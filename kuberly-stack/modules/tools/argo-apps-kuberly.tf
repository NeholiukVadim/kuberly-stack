resource "kubectl_manifest" "argocd_kuberly_project" {
  yaml_body = <<YAML
kind: AppProject
apiVersion: argoproj.io/v1alpha1
metadata:
  name: kuberly
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

resource "kubectl_manifest" "argocd_kuberly_app_set" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: kuberly
  namespace: argocd
spec:
  generators:
    - git:
        directories:
          - path: helm/*
        repoURL: git@bitbucket.org:kuberly/infrastructure.git
        %{ if var.environment == "prod" }
        revision: prod
        %{else}
        revision: main
        %{ endif }
  template:
    metadata:
      name: '{{path.basename}}'
      namespace: argocd
    spec:
      destination:
        namespace: kuberly
        server: https://kubernetes.default.svc
      project: kuberly
      source:
        path: 'helm/{{path.basename}}'
        repoURL: git@bitbucket.org:kuberly/infrastructure.git
        %{ if var.environment == "prod" }
        targetRevision: prod
        %{else}
        targetRevision: main
        %{ endif }
        helm:
          passCredentials: true
          valueFiles:
            - ${var.environment}.yaml
      %{ if var.environment != "prod" }
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
      %{ endif }
YAML
  depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "argocd_operator_app" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: k8s-operator-controller
  namespace: argocd
spec:
  project: kuberly
  source:
    repoURL: git@bitbucket.org:kuberly/k8s-operator.git
    %{ if var.environment == "prod" }
    targetRevision: prod
    path: config/default/prod
    %{else}
    targetRevision: main
    path: config/default/dev
    %{ endif }
  destination:
    server: 'https://kubernetes.default.svc'
  %{ if var.environment != "prod" }
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
  %{ endif }
YAML
  depends_on = [helm_release.argocd]
}