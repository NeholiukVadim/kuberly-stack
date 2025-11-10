resource "aws_ecrpublic_repository" "istio" {
  provider = aws.us_east_1

  repository_name = "istio"

  catalog_data {
    about_text        = "Istio is a service mesh for Kubernetes"
    architectures     = ["ARM", "X86"]
    description       = "Istio is a service mesh for Kubernetes"
    # logo_image_blob   = filebase64("${path.module}/istio.png")
    operating_systems = ["Linux"]
    usage_text        = "Istio is a service mesh for Kubernetes"
  }
}

resource "aws_ecrpublic_repository" "tools" {
  provider = aws.us_east_1

  repository_name = "tools"

  catalog_data {
    about_text        = "Tool images for the clusters"
    architectures     = ["ARM", "X86"]
    description       = "Tool images for the clusters"
    # logo_image_blob   = filebase64("${path.module}/istio.png")
    operating_systems = ["Linux"]
    usage_text        = "Tool images for the clusters"
  }
}

resource "aws_ecrpublic_repository" "multi-arch-ci-buildah" {
  provider = aws.us_east_1

  repository_name = "multi-arch-ci-buildah"

  catalog_data {
    about_text        = "ECR credential helper with multi arch support"
    architectures     = ["ARM", "X86"]
    description       = "ECR credential helper with multi arch support"
    operating_systems = ["Linux"]
    usage_text        = "ECR credential helper with multi arch support"
  }
}
resource "aws_ecrpublic_repository" "cloudtty" {
  provider = aws.us_east_1

  repository_name = "cloudtty"
  catalog_data {
    about_text = "Kubernetes Cloud Shell Operator Helm chart"
  }
}