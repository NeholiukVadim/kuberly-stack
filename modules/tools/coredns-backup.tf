# CoreDNS ConfigMap Backup CronJob
# This CronJob creates daily backups of the CoreDNS ConfigMap and maintains them for 7 days

resource "kubernetes_service_account_v1" "coredns_backup" {
  metadata {
    name      = "coredns-backup"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_v1" "coredns_backup" {
  metadata {
    name = "coredns-backup-cluster-role"
  }
  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["get", "create", "delete", "list"]
  }
  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["get"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "coredns_backup" {
  metadata {
    name = "coredns-backup-cluster-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.coredns_backup.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.coredns_backup.metadata[0].name
    namespace = kubernetes_service_account_v1.coredns_backup.metadata[0].namespace
  }
}

resource "kubernetes_cron_job_v1" "coredns_backup" {
  metadata {
    name      = "coredns-configmap-backup"
    namespace = "kube-system"
  }
  spec {
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = 1
    successful_jobs_history_limit = 1
    schedule                      = var.environment == "prod" ? "0 0 * * *" : "0 14 * * *"
    job_template {
      metadata {}
      spec {
        backoff_limit = 3
        template {
          metadata {}
          spec {
            container {
              name              = "backup"
              image             = "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/tech-images:kubectl-1-33-3"
              image_pull_policy = "IfNotPresent"

              resources {
                limits = {
                  cpu    = "50m"
                  memory = "64Mi"
                }
                requests = {
                  cpu    = "50m"
                  memory = "64Mi"
                }
              }

              command = ["/bin/bash", "-c"]
              args = [
                <<-EOT
                  #!/bin/bash
                  set -euo pipefail

                  echo "Starting CoreDNS ConfigMap backup process..."

                  # Get current timestamp for backup naming
                  TIMESTAMP=$$(date -u +%Y%m%d-%H%M%S)
                  BACKUP_NAME="coredns-backup-$${TIMESTAMP}"
                  
                  echo "Creating backup: $${BACKUP_NAME}"

                  # Check if original CoreDNS ConfigMap exists
                  if ! kubectl get configmap coredns -n kube-system >/dev/null 2>&1; then
                    echo "ERROR: CoreDNS ConfigMap not found in kube-system namespace"
                    exit 1
                  fi

                  # Create backup of the CoreDNS ConfigMap
                  kubectl get configmap coredns -n kube-system -o yaml | \
                    sed "s/name: coredns/name: $${BACKUP_NAME}/" | \
                    sed '/^  uid:/d' | \
                    sed '/^  resourceVersion:/d' | \
                    sed '/^  generation:/d' | \
                    sed '/^  creationTimestamp:/d' | \
                    sed '/^  managedFields:/,/^  [a-zA-Z]/d' | \
                    sed '/^status:/,/^[a-zA-Z]/d' | \
                    kubectl apply -f -

                  if [ $$? -eq 0 ]; then
                    echo "Successfully created backup: $${BACKUP_NAME}"
                  else
                    echo "ERROR: Failed to create backup: $${BACKUP_NAME}"
                    exit 1
                  fi

                  # Clean up old backups (older than 7 days)
                  echo "Cleaning up backups older than 7 days..."
                  
                  # Get current time in epoch
                  NOW=$$(date -u +%s)
                  SEVEN_DAYS_AGO=$$((NOW - 7 * 24 * 60 * 60))

                  # List all coredns-backup-* ConfigMaps and check their age
                  kubectl get configmaps -n kube-system -o json | \
                    jq -c '.items[] | select(.metadata.name | startswith("coredns-backup-")) | {name: .metadata.name, creationTimestamp: .metadata.creationTimestamp}' | \
                    while read -r backup_info; do
                      if [ -z "$$backup_info" ]; then
                        continue
                      fi
                      
                      backup_name=$$(echo "$$backup_info" | jq -r '.name // empty')
                      creation_time=$$(echo "$$backup_info" | jq -r '.creationTimestamp // empty')
                      
                      if [ -z "$$backup_name" ] || [ -z "$$creation_time" ]; then
                        echo "Skipping invalid backup data"
                        continue
                      fi
                      
                      # Convert creation timestamp to epoch
                      if ! creation_epoch=$$(date -d "$$creation_time" +%s 2>/dev/null); then
                        echo "Failed to parse creation time for $$backup_name"
                        continue
                      fi
                      
                      # Check if backup is older than 7 days
                      if [ "$$creation_epoch" -lt "$$SEVEN_DAYS_AGO" ]; then
                        echo "Deleting old backup: $$backup_name (created: $$creation_time)"
                        if kubectl delete configmap "$$backup_name" -n kube-system; then
                          echo "Successfully deleted old backup: $$backup_name"
                        else
                          echo "Failed to delete old backup: $$backup_name"
                        fi
                      else
                        echo "Keeping backup: $$backup_name (age: $$(( (NOW - creation_epoch) / 86400 )) days)"
                      fi
                    done

                  echo "CoreDNS ConfigMap backup process completed successfully"
                EOT
              ]
            }
            restart_policy = "Never"
            service_account_name = "coredns-backup"
            
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
            toleration {
              key      = "CriticalAddonsOnly"
              operator = "Exists"
            }
            toleration {
              effect   = "NoSchedule"
              key      = "node-role.kubernetes.io/control-plane"
            }
            
            node_selector = {
              "kubernetes.io/arch" = "arm64"
              "karpenter.sh/capacity-type" = var.environment == "prod" ? "on-demand" : "spot"
            }
          }
        }
      }
    }
  }
} 