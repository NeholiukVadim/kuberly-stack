locals {
  image = {
    repository = "oamdev/vela-core"
    tag        = "v1.9.11"
  }
  sa_name      = "kubevela-vela-core"
  sa_namespace = "vela-system"
}

data "aws_iam_policy" "kubevela" {
  name = "ReadOnlyAccess"
}

data "aws_iam_policy" "ecr_full_access" {
  name = "AmazonEC2ContainerRegistryFullAccess"
}

resource "helm_release" "kubevela" {
  namespace        = "vela-system"
  create_namespace = true

  name       = "kubevela"
  chart      = "vela-core"
  repository = "https://kubevela.github.io/charts"
  version    = "v1.9.11"

  values = [templatefile("./values/kubevela.yaml", {
    repository = local.image.repository
    tag        = local.image.tag
    role_arn   = var.kuberly_internal_role_arn
    sa_name    = local.sa_name
    aws_zone   = var.aws_zone
  })]
}

module "kubevela" {
  source           = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version          = "~> 5.0"
  role_name_prefix = "kubevela-"

  role_policy_arns = {
    policy = data.aws_iam_policy.kubevela.arn,
    policy = data.aws_iam_policy.ecr_full_access.arn,
  }

  oidc_providers = {
    main = {
      provider_arn               = var.cluster_oidc_provider_arn
      namespace_service_accounts = ["${local.sa_namespace}:${local.sa_name}"]
    }
  }
}

resource "kubernetes_job_v1" "vela_enable_addons" {
  for_each = toset([ "vela-prism", "vela-workflow"]) #"vela-core-shard-manager", "velaux"

  metadata {
    name      = "vela-enable-${each.key}-addon"
    namespace = "vela-system"
    labels = {
      "app" = "vela-cli"
    }
  }
  spec {
    ttl_seconds_after_finished = 0
    template {
      metadata {
        name = "install-${each.key}-addon"
        labels = {
          "app" = "vela-cli"
        }
      }
      spec {
        container {
          name              = "install"
          image             = "oamdev/vela-cli:${local.image.tag}"
          image_pull_policy = "IfNotPresent"

          command = ["/bin/sh", "-c"]
          args = each.key == "vela-core-shard-manager" ? [
            "vela addon enable ${each.key} nShards=3 || echo 'Ignoring error'; exit 0"
          ] : [
            "vela addon enable ${each.key} || echo 'Ignoring error'; exit 0"
          ]
        }
        restart_policy = "Never"
        service_account_name = "kubevela-vela-core"
      }
    }
  }
  wait_for_completion = false
  
  depends_on = [ helm_release.kubevela ]
}

resource "kubernetes_cron_job_v1" "fluxcd_restart" {
  metadata {
    name      = "vela-fluxcd-restart-workflow"
    namespace = "vela-system"
  }
  spec {
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = 1
    successful_jobs_history_limit = 1
    schedule                      = "*/3 * * * *"
    job_template {
      metadata {}
      spec {
        backoff_limit = 2
        template {
          metadata {}
          spec {
            container {
              name              = "restart"
              image             = "oamdev/vela-cli:${local.image.tag}"
              image_pull_policy = "IfNotPresent"

              command = ["/bin/sh", "-c"]
              args = [<<-EOT
                apk add jq
                # Get list of all clusters
                CLUSTERS=$(vela cluster list | awk '{print $1}' | grep -Ev '^local|^CLUSTER')
                
                # Get FluxCD status
                STATUS=$(vela status -n vela-system addon-fluxcd -o json)
                
                # Flag to track if restart is needed
                NEED_RESTART=0
                
                # Check each cluster
                for cluster in $CLUSTERS; do
                  # Check if cluster exists in FluxCD helm controller status and is healthy
                  if ! echo "$STATUS" | jq -e --arg cluster "$cluster" '.status.services[] | select(.name=="fluxcd-helm-controller" and .cluster==$cluster and .healthy==true)' > /dev/null; then
                    echo "Cluster $cluster: FluxCD helm controller is not healthy or missing"
                    NEED_RESTART=1
                    break
                  fi
                done
                
                # Restart if needed
                if [ "$NEED_RESTART" -eq 1 ]; then
                  echo "Restarting FluxCD plugin"
                  vela workflow restart -n vela-system addon-fluxcd
                else
                  echo "FluxCD is healthy on all clusters"
                fi
              EOT
              ]
            }
            restart_policy = "Never"
            service_account_name = "kubevela-vela-core"
            
            toleration {
              key      = "karpenter.sh/disruption"
              operator = "Equal"
              value    = "disrupting"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "type"
              operator = "Equal"
              value    = "karpenter"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "on-demand"
              operator = "Equal"
              value    = "true"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "spot"
              operator = "Equal"
              value    = "true"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "type"
              operator = "Equal"
              value    = "karpenter"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "arch/arm"
              operator = "Equal"
              value    = "true"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "arch/amd"
              operator = "Equal"
              value    = "true"
              effect   = "NoSchedule"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_account_v1" "vela_cloudshell_cleanup" {
  metadata {
    name      = "vela-cloudshell-cleanup"
    namespace = "vela-system"
  }
}

resource "kubernetes_cluster_role_v1" "vela_cleanup" {
  metadata {
    name = "vela-cleanup-cluster-role"
  }
  rule {
    api_groups = ["core.oam.dev"]
    resources  = ["applications", "applications/status", "workflows"]
    verbs      = ["*"]
  }
  rule {
    api_groups = ["apiregistration.k8s.io"]
    resources  = ["apiservices"]
    verbs      = ["get", "list"]
  }
  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["get", "list", "create"]
  }
  rule {
    api_groups = ["cluster.core.oam.dev"]
    resources  = ["clusters"]
    verbs      = ["get", "list"]
  }
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list"]
  }
}

resource "kubernetes_service_account_v1" "vela_cleanup_vela_system" {
  metadata {
    name      = "vela-cleanup"
    namespace = "vela-system"
  }
}

resource "kubernetes_cluster_role_binding_v1" "vela_cleanup_vela_system" {
  metadata {
    name = "vela-cleanup-cluster-binding-vela-system"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.vela_cleanup.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.vela_cleanup_vela_system.metadata[0].name
    namespace = kubernetes_service_account_v1.vela_cleanup_vela_system.metadata[0].namespace
  }
}

resource "kubernetes_cron_job_v1" "vela_cloudshell_cleanup" {
  metadata {
    name      = "vela-cloudshell-cleanup"
    namespace = "vela-system"
  }
  spec {
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = 1
    successful_jobs_history_limit = 1
    schedule                      = "0 * * * *"
    job_template {
      metadata {}
      spec {
        backoff_limit = 2
        template {
          metadata {}
          spec {
            container {
              name              = "cleanup"
              image             = "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/tech-images:kubectl-1-33-3"
              image_pull_policy = "IfNotPresent"

              command = ["/bin/bash", "-c"]
              args = [
                <<-EOT
                  #!/bin/bash
                  set -euo pipefail

                  # Current time in epoch
                  NOW=$$(date -u +%s)

                  # Get Vela applications with shell-v* type
                  kubectl get applications.core.oam.dev -A -o json | \
                    jq -c '.items[] | select(.spec.components[].type | startswith("shell-v"))' | \
                    while read -r app; do
                      if [ -z "$$app" ]; then
                        continue
                      fi
                    name=$$(echo "$$app" | jq -r '.metadata.name // empty')
                    namespace=$$(echo "$$app" | jq -r '.metadata.namespace // empty')
                    creation_time=$$(echo "$$app" | jq -r '.metadata.creationTimestamp // empty')
                    if [ -z "$$name" ] || [ -z "$$namespace" ] || [ -z "$$creation_time" ]; then
                      echo "Skipping invalid application data"
                      continue
                    fi
                    if ! creation_epoch=$$(date -d "$$creation_time" +%s 2>/dev/null); then
                      echo "Failed to parse creation time for $$name in $$namespace"
                      continue
                    fi
                      age_minutes=$$(( (NOW - creation_epoch) / 60 ))
                      age_minutes=$$(( (NOW - creation_epoch) / 60 ))

                    age_minutes=$$(( (NOW - creation_epoch) / 60 ))

                    if [ "$$age_minutes" -gt 30 ]; then
                      echo "Deleting $$name in $$namespace (age: $${age_minutes}m)"
                      if ! kubectl delete application.core.oam.dev "$$name" -n "$$namespace"; then
                        echo "Failed to delete $$name in $$namespace"
                      fi
                    fi
                  done
              EOT
              ]
            }
            restart_policy = "Never"
            service_account_name = kubernetes_service_account_v1.vela_cleanup_vela_system.metadata[0].name
            toleration {
              key      = "karpenter.sh/disruption"
              operator = "Equal"
              value    = "disrupting"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "type"
              operator = "Equal"
              value    = "karpenter"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "on-demand"
              operator = "Equal"
              value    = "true"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "spot"
              operator = "Equal"
              value    = "true"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "type"
              operator = "Equal"
              value    = "karpenter"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "arch/arm"
              operator = "Equal"
              value    = "true"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "arch/amd"
              operator = "Equal"
              value    = "true"
              effect   = "NoSchedule"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_cron_job_v1" "vela_ci_cleanup" {
  metadata {
    name      = "vela-ci-cleanup"
    namespace = "vela-system"
  }
  spec {
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = 1
    successful_jobs_history_limit = 1
    schedule                      = "0 * * * *"
    job_template {
      metadata {}
      spec {
        backoff_limit = 2
        template {
          metadata {}
          spec {
            container {
              name              = "cleanup"
              image             = "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/tech-images:kubectl-1-33-3"
              image_pull_policy = "IfNotPresent"
              command = ["/bin/bash", "-c"]
              args = [
                <<-EOT
                  #!/bin/bash
                  set -euo pipefail

                  # Current time in epoch
                  NOW=$$(date -u +%s)

                  # Get Vela applications with ci-v* type
                  kubectl get applications.core.oam.dev -A -o json -n ci | \
                    jq -c '.items[] | select(.spec.components[].type | startswith("ci-v"))' | \
                    while read -r app; do
                      if [ -z "$$app" ]; then
                        continue
                      fi
                    name=$$(echo "$$app" | jq -r '.metadata.name // empty')
                    creation_time=$$(echo "$$app" | jq -r '.metadata.creationTimestamp // empty')
                    if [ -z "$$name" ] || [ -z "ci" ] || [ -z "$$creation_time" ]; then
                      echo "Skipping invalid application data"
                      continue
                    fi
                    if ! creation_epoch=$$(date -d "$$creation_time" +%s 2>/dev/null); then
                      echo "Failed to parse creation time for $$name in ci"
                      continue
                    fi
                    age_minutes=$$(( (NOW - creation_epoch) / 60 ))
                    if [ "$$age_minutes" -gt 60 ]; then
                      echo "Deleting $$name in ci (age: $${age_minutes}m)"
                      if ! kubectl delete application.core.oam.dev "$$name" -n ci; then
                        echo "Failed to delete $$name in ci"
                      fi
                    fi
                  done
              EOT
              ]
            }
            restart_policy = "Never"
            service_account_name = kubernetes_service_account_v1.vela_cleanup_vela_system.metadata[0].name
            toleration {
              key      = "karpenter.sh/disruption"
              operator = "Equal"
              value    = "disrupting"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "type"
              operator = "Equal"
              value    = "karpenter"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "on-demand"
              operator = "Equal"
              value    = "true"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "spot"
              operator = "Equal"
              value    = "true"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "type"
              operator = "Equal"
              value    = "karpenter"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "arch/arm"
              operator = "Equal"
              value    = "true"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "arch/amd"
              operator = "Equal"
              value    = "true"
              effect   = "NoSchedule"
            }
          }
        }
      }
    }
  }
} 

resource "kubernetes_cron_job_v1" "vela_cluster_sleep_applications" {
  count = var.environment == "dev" ? 1 : 0
  metadata {
    name      = "vela-cluster-sleep-applications"
    namespace = "vela-system"
  }
  spec {
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = 1
    successful_jobs_history_limit = 1
    schedule                      = "50 20 * * 1-5"
    job_template {
      metadata {}
      spec {
        backoff_limit = 2
        template {
          metadata {}
          spec {
            container {
              name              = "cluster-sleep-applications"
              image             = "public.ecr.aws/n3h0s9r7/istio:k8s-tools"
              image_pull_policy = "IfNotPresent"
              command = ["/bin/bash", "-c"]
              args = [
                <<-EOT
                  #!/bin/bash
                  set -euo pipefail

                  echo "Starting Vela sleep applications setup"

                  # Install vela CLI
                  echo "Installing Vela CLI..."
                  curl -fsSL https://kubevela.io/script/install.sh | bash
                  export PATH=$$PATH:$$HOME/.vela/bin

                  # Verify vela CLI installation
                  if ! command -v vela &> /dev/null; then
                    echo "Error: Vela CLI installation failed"
                    exit 1
                  fi

                  echo "Vela CLI installed successfully"

                  # Get list of clusters with better error handling
                  echo "Getting cluster list..."
                  
                  # First, check if vela cluster list works
                  if ! vela cluster list >/dev/null 2>&1; then
                    echo "Error: vela cluster list command failed"
                    echo "Checking vela version and status..."
                    vela version
                    exit 1
                  fi
                  
                  # Get raw output for debugging
                  echo "Raw vela cluster list output:"
                  vela cluster list
                  
                  # Parse cluster list properly - get each cluster name on a separate line
                  echo "Parsing cluster list..."
                  CLUSTER_LIST=$$(vela cluster list 2>/dev/null | tail -n +2 | awk '{print $$1}' | grep -v '^$$' | grep -v "^$$")
                  
                  # If empty, try alternative parsing
                  if [ -z "$$CLUSTER_LIST" ]; then
                    echo "Trying alternative parsing method..."
                    CLUSTER_LIST=$$(vela cluster list 2>/dev/null | grep -v "CLUSTER" | grep -v "ALIAS" | awk '{print $$1}' | grep -v '^$$')
                  fi
                  
                  # If still empty, try without tail
                  if [ -z "$$CLUSTER_LIST" ]; then
                    echo "Trying without tail..."
                    CLUSTER_LIST=$$(vela cluster list 2>/dev/null | awk '{print $$1}' | grep -v "CLUSTER" | grep -v '^$$')
                  fi

                  echo "Found clusters:"
                  echo "$$CLUSTER_LIST"

                  if [ -z "$$CLUSTER_LIST" ]; then
                    echo "No clusters found after parsing"
                    echo "This might be normal if no clusters are configured"
                    exit 0
                  fi

                  # Function to process a single cluster
                  process_cluster() {
                    local cluster_name="$$1"
                    
                    if [ -z "$$cluster_name" ]; then
                      echo "Skipping empty cluster name"
                      return
                    fi

                    # Skip the 'local' cluster
                    if [ "$$cluster_name" = "local" ]; then
                      echo "Skipping local cluster"
                      return
                    fi

                    echo "Processing cluster: $$cluster_name"

                    # Use cluster name as namespace and application name (sanitized)
                    # Limit namespace name to 63 characters and ensure it starts with alphanumeric
                    NAMESPACE=$$(echo "$$cluster_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/^[^a-z0-9]*//' | sed 's/[^a-z0-9]*$$//' | cut -c1-63)
                    APP_NAME=$$(echo "$$cluster_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/^[^a-z0-9]*//' | sed 's/[^a-z0-9]*$$//' | cut -c1-63)
                    
                    if [ -z "$$APP_NAME" ]; then
                      echo "Invalid cluster name after sanitization: $$cluster_name"
                      return
                    fi

                    # Ensure namespace starts with alphanumeric character
                    if ! echo "$$NAMESPACE" | grep -q '^[a-z0-9]'; then
                      NAMESPACE="cluster-$$NAMESPACE"
                    fi
                    if ! echo "$$APP_NAME" | grep -q '^[a-z0-9]'; then
                      APP_NAME="app-$$APP_NAME"
                    fi

                    echo "Using namespace: $$NAMESPACE"
                    echo "Using app name: $$APP_NAME"

                    # Create namespace if it doesn't exist
                    if ! kubectl get namespace "$$NAMESPACE" >/dev/null 2>&1; then
                      echo "Creating namespace: $$NAMESPACE"
                      kubectl create namespace "$$NAMESPACE"
                    fi

                    # Check if application already exists
                    if kubectl get application.core.oam.dev "$$APP_NAME" -n "$$NAMESPACE" >/dev/null 2>&1; then
                      echo "Application $$APP_NAME already exists in namespace $$NAMESPACE, skipping"
                      return
                    fi

                    echo "Creating application $$APP_NAME in namespace $$NAMESPACE for cluster $$cluster_name"

                    # Create application YAML
                    cat <<EOF | kubectl apply -f -
apiVersion: core.oam.dev/v1beta1
kind: Application
metadata:
  name: "$$APP_NAME"
  namespace: "$$NAMESPACE"
spec:
  components:
    - name: "$$APP_NAME"
      type: eks-sleep-application-v0.0.13
      properties:
        namespace: "$$NAMESPACE"
EOF

                    echo "Created application $$APP_NAME for cluster $$cluster_name"
                  }

                  # Process each cluster
                  echo "Processing clusters..."
                  echo "$$CLUSTER_LIST" | while IFS= read -r cluster_name; do
                    process_cluster "$$cluster_name"
                  done

                  echo "Sleep applications setup completed successfully!"

                  # Optional: List all created applications
                  echo ""
                  echo "Created applications:"
                  kubectl get applications.core.oam.dev --all-namespaces || echo "No applications found"
                EOT
              ]
            }
            restart_policy = "Never"
            service_account_name = kubernetes_service_account_v1.vela_cleanup_vela_system.metadata[0].name
            toleration {
              key      = "karpenter.sh/disruption"
              operator = "Equal"
              value    = "disrupting"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "type"
              operator = "Equal"
              value    = "karpenter"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "on-demand"
              operator = "Equal"
              value    = "true"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "spot"
              operator = "Equal"
              value    = "true"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "type"
              operator = "Equal"
              value    = "karpenter"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "arch/arm"
              operator = "Equal"
              value    = "true"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "arch/amd"
              operator = "Equal"
              value    = "true"
              effect   = "NoSchedule"
            }
          }
        }
      }
    }
  }
} 

resource "kubernetes_cron_job_v1" "vela_cluster_wake_applications" {
  count = var.environment == "dev" ? 1 : 0
  metadata {
    name      = "vela-cluster-wake-applications"
    namespace = "vela-system"
  }
  spec {
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = 1
    successful_jobs_history_limit = 1
    schedule                      = "15 6 * * 1-5"
    job_template {
      metadata {}
      spec {
        backoff_limit = 2
        template {
          metadata {}
          spec {
            container {
              name              = "cluster-wake-applications"
              image             = "public.ecr.aws/n3h0s9r7/istio:k8s-tools"
              image_pull_policy = "IfNotPresent"
              command = ["/bin/bash", "-c"]
              args = [
                <<-EOT
                  #!/bin/bash
                  set -euo pipefail

                  echo "Starting Vela wake applications cleanup and restart"

                  # Install vela CLI
                  echo "Installing Vela CLI..."
                  curl -fsSL https://kubevela.io/script/install.sh | bash
                  export PATH=$$PATH:$$HOME/.vela/bin

                  # Verify vela CLI installation
                  if ! command -v vela &> /dev/null; then
                    echo "Error: Vela CLI installation failed"
                    exit 1
                  fi

                  echo "Vela CLI installed successfully"

                  # Get list of clusters with better error handling
                  echo "Getting cluster list..."
                  
                  # First, check if vela cluster list works
                  if ! vela cluster list >/dev/null 2>&1; then
                    echo "Error: vela cluster list command failed"
                    echo "Checking vela version and status..."
                    vela version
                    exit 1
                  fi
                  
                  # Get raw output for debugging
                  echo "Raw vela cluster list output:"
                  vela cluster list
                  
                  # Parse cluster names properly - keep newlines for proper parsing
                  CLUSTER_DATA=$(vela cluster list 2>/dev/null | tail -n +2 | awk '{print $1}' | grep -v '^$')
                  
                  # If still empty, try alternative parsing
                  if [ -z "$CLUSTER_DATA" ]; then
                    echo "Trying alternative parsing method..."
                    CLUSTER_DATA=$(vela cluster list 2>/dev/null | grep -v "CLUSTER" | grep -v "ALIAS" | awk '{print $1}' | grep -v '^$')
                  fi
                  
                  # If still empty, try without tail
                  if [ -z "$CLUSTER_DATA" ]; then
                    echo "Trying without tail..."
                    CLUSTER_DATA=$(vela cluster list 2>/dev/null | awk '{print $1}' | grep -v "CLUSTER" | grep -v '^$')
                  fi

                  echo "Parsed cluster data: '$$CLUSTER_DATA'"

                  if [ -z "$$CLUSTER_DATA" ]; then
                    echo "No clusters found after parsing"
                    echo "This might be normal if no clusters are configured"
                  else
                    # Function to process a single cluster
                    process_cluster() {
                      local cluster_name="$$1"
                      
                      if [ -z "$$cluster_name" ]; then
                        echo "Skipping empty cluster name"
                        return
                      fi

                      # Skip the 'local' cluster
                      if [ "$$cluster_name" = "local" ]; then
                        echo "Skipping local cluster"
                        return
                      fi

                      echo "Processing cluster: $$cluster_name"

                      # Use cluster name as namespace and application name (sanitized)
                      NAMESPACE="$$cluster_name"
                      APP_NAME=$$(echo "$$cluster_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/^[^a-z0-9]*//' | sed 's/[^a-z0-9]*$$//')
                      
                      if [ -z "$$APP_NAME" ]; then
                        echo "Invalid cluster name after sanitization: $$cluster_name"
                        return
                      fi

                      # Check if sleep application exists and delete it
                      if kubectl get application.core.oam.dev "$$APP_NAME" -n "$$NAMESPACE" >/dev/null 2>&1; then
                        echo "Deleting sleep application $$APP_NAME from namespace $$NAMESPACE"
                        kubectl delete application.core.oam.dev "$$APP_NAME" -n "$$NAMESPACE"
                        echo "Sleep application $$APP_NAME deleted successfully"
                      else
                        echo "Sleep application $$APP_NAME not found in namespace $$NAMESPACE, skipping deletion"
                      fi
                    }

                    # Process each cluster - handle both single and multiple clusters
                    echo "Processing clusters for cleanup..."
                    
                    # Process each cluster line by line
                    echo "$CLUSTER_DATA" | while IFS= read -r cluster_name; do
                      if [ -n "$cluster_name" ]; then
                        process_cluster "$cluster_name"
                      fi
                    done
                  fi

                  echo "Sleep applications cleanup completed!"

                  # Restart applications for all clusters (except local)
                  echo "Starting application restart for all clusters..."
                  
                  if [ -z "$CLUSTER_DATA" ]; then
                    echo "No clusters found for restart process"
                  else
                    # Function to restart applications in a cluster
                    restart_cluster_apps() {
                      local cluster_name="$1"
                      
                      if [ -z "$cluster_name" ]; then
                        echo "Skipping empty cluster name for restart"
                        return
                      fi

                      # Skip the 'local' cluster
                      if [ "$cluster_name" = "local" ]; then
                        echo "Skipping local cluster for restart"
                        return
                      fi

                      echo "Restarting applications for cluster: $cluster_name"

                      # Use cluster name as namespace
                      NAMESPACE="$cluster_name"
                      
                      # Check if namespace exists
                      if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
                        echo "Namespace $NAMESPACE not found, skipping restart for cluster $cluster_name"
                        return
                      fi

                      # Get all applications in the namespace and filter for -flow ending
                      APPS=$(kubectl get applications.core.oam.dev -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
                      
                      if [ -z "$APPS" ]; then
                        echo "No applications found in namespace $NAMESPACE for cluster $cluster_name"
                        return
                      fi

                      # Filter applications to only those ending with -flow
                      FLOW_APPS=""
                      for app in $APPS; do
                        if [[ "$app" == *"-flow" ]]; then
                          FLOW_APPS="$FLOW_APPS $app"
                        fi
                      done

                      if [ -z "$FLOW_APPS" ]; then
                        echo "No applications ending with -flow found in namespace $NAMESPACE for cluster $cluster_name"
                        return
                      fi

                      echo "Found flow applications in $NAMESPACE: $FLOW_APPS"

                      # Restart each -flow application in the namespace
                      for app_name in $FLOW_APPS; do
                        echo "Restarting application: $app_name in namespace $NAMESPACE"
                        
                        if vela workflow restart "$app_name" -n "$NAMESPACE"; then
                          echo "Successfully restarted $app_name in $NAMESPACE"
                        else
                          echo "Failed to restart $app_name in $NAMESPACE, continuing with next application"
                        fi
                      done
                    }

                    # Process each cluster for restart - handle both single and multiple clusters
                    echo "Processing clusters for application restart..."
                    
                    # Process each cluster line by line for restart
                    echo "$CLUSTER_DATA" | while IFS= read -r cluster_name; do
                      if [ -n "$cluster_name" ]; then
                        restart_cluster_apps "$cluster_name"
                      fi
                    done
                  fi

                  echo "Application restart process completed!"

                  # Optional: List remaining applications
                  echo ""
                  echo "Remaining applications:"
                  kubectl get applications.core.oam.dev --all-namespaces | head -20 || echo "No applications found"
                EOT
              ]
            }
            restart_policy = "Never"
            service_account_name = kubernetes_service_account_v1.vela_cleanup_vela_system.metadata[0].name
            toleration {
              key      = "karpenter.sh/disruption"
              operator = "Equal"
              value    = "disrupting"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "type"
              operator = "Equal"
              value    = "karpenter"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "on-demand"
              operator = "Equal"
              value    = "true"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "spot"
              operator = "Equal"
              value    = "true"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "type"
              operator = "Equal"
              value    = "karpenter"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "arch/arm"
              operator = "Equal"
              value    = "true"
              effect   = "NoSchedule"
            }
            toleration {
              key      = "arch/amd"
              operator = "Equal"
              value    = "true"
              effect   = "NoSchedule"
            }
          }
        }
      }
    }
  }
}