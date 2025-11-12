resource "kubectl_manifest" "argocd_vela_project" {
  yaml_body = <<YAML
kind: AppProject
apiVersion: argoproj.io/v1alpha1
metadata:
  name: vela-templates
  namespace: argocd
spec:
  clusterResourceWhitelist:
    - group: '*'
      kind: '*'
  namespaceResourceWhitelist:
    - group: '*'
      kind: '*'
  destinations:
    - namespace: '*'
      server: 'https://kubernetes.default.svc'
  orphanedResources:
    ignore:
      - group: '*'
        kind: Secret
        name: tls-*
      - group: '*'
        kind: Secret
        name: sh.helm.release.*
  sourceRepos:
    - '*'
YAML

  depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "argocd_vela_app_set" {
  # We don't really need a copy of ECR on every env. That means we need its CodeBuild per env.
  count = var.environment == "dev" || var.environment == "prod" ? 1 : 0

  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: vela-modules
  namespace: argocd
spec:
  generators:
    - git:
        directories:
          - path: modules/*
        repoURL: git@bitbucket.org:kuberly/vela-templates.git
        %{ if var.environment == "prod" }
        revision: prod
        %{ else }
        revision: develop
        %{ endif }
  template:
    metadata:
      name: '{{path.basename}}'
    spec:
      destination:
        namespace: argocd
        server: https://kubernetes.default.svc
      project: vela-templates
      source:
        path: ./argocd/vela-module/${var.environment}
        repoURL: git@bitbucket.org:kuberly/infrastructure.git
        %{ if var.environment == "prod" }
        targetRevision: prod
        %{ else }
        targetRevision: main
        %{ endif }
        plugin:
          name: envsubst
          env:
          - name: MODULE_NAME
            value: '{{path.basename}}'
YAML
  depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "argocd_vela_def_app_set" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: vela-modules-definitions
  namespace: argocd
spec:
  generators:
    - git:
        directories:
          - path: modules/*
        repoURL: git@bitbucket.org:kuberly/vela-templates.git
        %{ if var.environment == "prod" }
        revision: prod
        %{ else }
        revision: develop
        %{ endif }
  template:
    metadata:
      name: '{{path.basename}}-definitions'
    spec:
      destination:
        namespace: argocd
        server: https://kubernetes.default.svc
      project: vela-templates
      source:
        path: ./
        repoURL: git@bitbucket.org:kuberly/vela-templates.git
        %{ if var.environment == "prod" }
        targetRevision: prod
        %{ else }
        targetRevision: develop
        %{ endif }
        plugin:
          name: velacli
          env:
          - name: MODULE_NAME
            value: '{{path.basename}}'
          - name: AWS_REGION
            value: "${var.aws_region}"
YAML
  depends_on = [helm_release.argocd]
}