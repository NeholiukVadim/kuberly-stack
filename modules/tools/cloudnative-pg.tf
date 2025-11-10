resource "helm_release" "cloudnative-pg" {
  count = var.environment != "prod" ? 1 : 0

  name             = "cloudnative-pg"
  namespace        = "cnpg-system"
  create_namespace = true
  repository       = "https://cloudnative-pg.github.io/charts"
  chart            = "cloudnative-pg"
  version          = "0.23.0"
  values           = [templatefile("./values/cloudnative-pg.yaml", {
    aws_zone       = var.aws_zone
  })]
}

resource "random_password" "cloudnative_pg_password" {
  count = var.environment != "prod" ? 1 : 0

  length  = 22
  special = false

  lifecycle {
    ignore_changes = [ special ]
  }
}

resource "kubernetes_secret_v1" "cloudnative_pg_secret" {
  count = var.environment != "prod" ? 1 : 0

  metadata {
    name      = "psql-admin-creds"
    namespace = "kuberly"
    labels = {
      "cnpg.io/reload" = "true"
    }
  }
  
  type = "kubernetes.io/basic-auth"
  data = {
    "username" = "kuberly"
    "password" = random_password.cloudnative_pg_password[0].result
  }
}

resource "kubernetes_secret_v1" "cloudnative_pg_creds_secret" {
  count = var.environment != "prod" ? 1 : 0

  metadata {
    name      = "psql-creds"
    namespace = "kuberly"
  }

  data = {
    "PG_DBNAME" = "kuberly"
    "PG_HOST" = "psql-db-rw"
    "PG_PASS" = random_password.cloudnative_pg_password[0].result
    "PG_USER" = "kuberly"
    "POSTGRES_DB" = "kuberly"
    "POSTGRES_HOST" = "psql-db-rw"
    "POSTGRES_PASSWORD" = "psql-db-rw:5432:kuberly:kuberly:${random_password.cloudnative_pg_password[0].result}"
    "POSTGRES_USER" = "kuberly"
  }
}

resource "kubectl_manifest" "cloudnative_pg_cluster" {
  count = var.environment != "prod" ? 1 : 0

  yaml_body = <<YAML
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: psql-db
  namespace: kuberly
spec:
  instances: 1
  monitoring:
    enablePodMonitor: true
  storage:
    size: 10Gi
  affinity:
    nodeSelector:
      karpenter.sh/capacity-type: on-demand
      topology.kubernetes.io/zone: "eu-west-1a"
    tolerations:
    - key: arch/arm
      operator: Equal
      value: "true"
      effect: NoSchedule
  bootstrap:
    initdb:
      database: kuberly
      owner: kuberly
      secret:
        name: psql-admin-creds
  managed:
    roles:
    - name: kuberly
      passwordSecret:
        name: psql-admin-creds
      comment: "Role with superuser permissions and login access"
      connectionLimit: -1
      createdb: true
      createrole: true
      login: true
      superuser: true
  resources:
    requests:
      cpu: "100m"
      memory: "256Mi"
    limits:
      cpu: "100m"
      memory: "256Mi"
YAML

  depends_on = [helm_release.cloudnative-pg, kubernetes_secret_v1.cloudnative_pg_secret]
}