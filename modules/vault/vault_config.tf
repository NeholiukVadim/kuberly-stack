# Ensure port-forward is running
resource "null_resource" "vault_port_forward" {
  depends_on = [helm_release.vault]

  provisioner "local-exec" {
    command = <<-EOT
      # Kill any existing port-forward
      pkill -f 'kubectl port-forward svc/vault 8200:8200 --namespace vault' || true
      
      # Start new port-forward in background
      nohup kubectl port-forward svc/vault 8200:8200 --namespace vault >/dev/null 2>&1 &
      echo $! > /tmp/vault-port-forward.pid
      
      # Wait for port-forward to be ready
      for i in {1..30}; do
        if curl -s http://localhost:8200/v1/sys/health >/dev/null 2>&1; then
          echo "Vault port-forward is ready"
          break
        fi
        echo "Waiting for Vault port-forward... ($i/30)"
        sleep 2
      done
    EOT
  }

  provisioner "local-exec" {
    when = destroy
    command = "pkill -f 'kubectl port-forward svc/vault 8200:8200 --namespace vault' || true; rm -f /tmp/vault-port-forward.pid"
  }
}

# Wait for port-forward to be established
resource "time_sleep" "wait_for_port_forward" {
  depends_on = [null_resource.vault_port_forward]
  create_duration = "10s"
}

# Vault provider configuration using kubectl port-forward
provider "vault" {
  address = "http://localhost:8200"
  token   = data.kubernetes_secret.vault_unseal_keys.data["vault-root"]
}

# Enable PKI secrets engine for client certificates
resource "vault_mount" "pki_client" {
  depends_on = [time_sleep.wait_for_port_forward]
  path        = "pki-client"
  type        = "pki"
  description = "PKI secrets engine for client certificates"
  default_lease_ttl_seconds = 0
  max_lease_ttl_seconds     = 315360000  # 10 years in seconds (87600h)
}

# Generate intermediate CA CSR
resource "vault_pki_secret_backend_intermediate_cert_request" "pki_client" {
  depends_on = [vault_mount.pki_client]
  backend    = vault_mount.pki_client.path

  type        = "internal"
  common_name = "Kuberly Client Intermediate"
  key_type    = "rsa"
  key_bits    = 2048
}

# Create PKI role for cert-manager
resource "vault_pki_secret_backend_role" "cert_manager" {
  depends_on = [vault_pki_secret_backend_intermediate_cert_request.pki_client]
  backend    = vault_mount.pki_client.path
  name       = "cert-manager"

  allowed_domains    = ["*.${var.dns_domain}", var.dns_domain]
  allow_subdomains   = true
  allow_glob_domains = true
  allow_any_name     = false
  allow_ip_sans      = true
  server_flag        = false
  client_flag        = true
  code_signing_flag  = false
  email_protection_flag = false
  key_usage          = ["DigitalSignature", "KeyEncipherment"]
  ext_key_usage      = ["ClientAuth"]
  ttl                = 2592000
  max_ttl            = 7776000
}

# Create PKI role for kuberly-client (matches your cert-manager config)
resource "vault_pki_secret_backend_role" "kuberly_client" {
  depends_on = [vault_pki_secret_backend_intermediate_cert_request.pki_client]
  backend    = vault_mount.pki_client.path
  name       = "kuberly-client"

  # Allow both the configured dns_domain and gw.pl.kuberly.io for test2 environment
  allowed_domains    = ["*.${var.dns_domain}", var.dns_domain, "*.gw.pl.kuberly.io", "gw.pl.kuberly.io"]
  allow_subdomains   = true
  allow_glob_domains = true
  allow_any_name     = false
  allow_ip_sans      = true
  server_flag        = false
  client_flag        = true
  code_signing_flag  = false
  email_protection_flag = false
  key_usage          = ["DigitalSignature", "KeyEncipherment"]
  ext_key_usage      = ["ClientAuth"]
  ttl                = 2592000
  max_ttl            = 7776000
}

# Enable Kubernetes authentication method
resource "vault_auth_backend" "kubernetes" {
  depends_on = [time_sleep.wait_for_port_forward]
  type = "kubernetes"
  path = "kubernetes"
}

# Configure Kubernetes authentication
resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  depends_on = [vault_auth_backend.kubernetes, kubernetes_secret.vault_token]
  backend    = vault_auth_backend.kubernetes.path

  kubernetes_host    = "https://kubernetes.default.svc:443"
  kubernetes_ca_cert = kubernetes_secret.vault_token.data["ca.crt"]
  token_reviewer_jwt = kubernetes_secret.vault_token.data["token"]
}

# Create policy for PKI client certificate issuance
resource "vault_policy" "pki_client_issue" {
  depends_on = [time_sleep.wait_for_port_forward]
  name = "pki-client-issue"

  policy = <<EOT
# Allow cert-manager to issue certificates from pki-client
path "pki-client/issue/cert-manager" {
  capabilities = ["create", "update"]
}

path "pki-client/issue/kuberly-client" {
  capabilities = ["create", "update"]
}

# Allow cert-manager to sign certificates (for kuberly-client role)
path "pki-client/sign/kuberly-client" {
  capabilities = ["create", "update"]
}

# Allow cert-manager to read PKI client configuration
path "pki-client/config/*" {
  capabilities = ["read"]
}

# Allow cert-manager to read PKI client roles
path "pki-client/roles/*" {
  capabilities = ["read"]
}

# Allow cert-manager to read PKI client CA
path "pki-client/cert/ca" {
  capabilities = ["read"]
}

# Allow cert-manager to read PKI client CA chain
path "pki-client/cert/ca_chain" {
  capabilities = ["read"]
}
EOT
}

# Create Kubernetes authentication role for cert-manager
resource "vault_kubernetes_auth_backend_role" "cert_manager_client" {
  depends_on = [vault_kubernetes_auth_backend_config.kubernetes]
  backend    = vault_auth_backend.kubernetes.path
  role_name  = "cert-manager-client"

  bound_service_account_names      = ["cert-manager"]
  bound_service_account_namespaces = ["cert-manager"]
  token_policies                   = [vault_policy.pki_client_issue.name]
  token_ttl                        = 3600 # 1 hour
}

# Create cert-manager ClusterIssuer
resource "kubernetes_manifest" "kuberly_client_issuer" {
  depends_on = [vault_pki_secret_backend_role.kuberly_client]
  
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name      = "kuberly-client-issuer"
    }
    spec = {
      vault = {
        server = "http://vault.vault.svc:8200"
        path   = "pki-client/sign/kuberly-client"
        auth = {
          kubernetes = {
            mountPath = "/v1/auth/kubernetes"
            role      = "cert-manager-client"
            serviceAccountRef = {
              name = "cert-manager"
            }
          }
        }
      }
    }
  }
}
