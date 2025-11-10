locals {
  csi-external-snapshotter_yaml_files = [
    "https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${var.csi_external_snapshotter_version}/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml",
    "https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${var.csi_external_snapshotter_version}/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml",
    "https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${var.csi_external_snapshotter_version}/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml",
    "https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${var.csi_external_snapshotter_version}/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml",
    "https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${var.csi_external_snapshotter_version}/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml"
  ]

  csi-external-snapshotter_apply = [for v in data.kubectl_file_documents.csi-external-snapshotter.documents : {
    data : yamldecode(v)
    content : v
    }
  ]

  # Process the YAML documents and add tolerations/node selectors to the deployment
  processed_documents = [
    for doc in local.csi-external-snapshotter_apply : 
      doc.data.kind == "Deployment" && doc.data.metadata.name == "snapshot-controller" ? 
        yamlencode(merge(doc.data, {
          spec = merge(doc.data.spec, {
            template = merge(doc.data.spec.template, {
              spec = merge(doc.data.spec.template.spec, {
                tolerations = var.csi_external_snapshotter_tolerations
                nodeSelector = var.csi_external_snapshotter_node_selector
                containers = [
                  for container in doc.data.spec.template.spec.containers : merge(container, {
                    resources = var.csi_external_snapshotter_resources
                  })
                ]
              })
            })
          })
        })) : 
        doc.content
  ]
}

data "http" "csi-external-snapshotter" {
  for_each = toset(local.csi-external-snapshotter_yaml_files)
  url      = each.key
}

data "kubectl_file_documents" "csi-external-snapshotter" {
  content = join("\n---\n", [for k, v in data.http.csi-external-snapshotter : v.response_body])
}

resource "kubectl_manifest" "csi-external-snapshotter" {
  for_each  = {
    for i, v in local.processed_documents : 
      lower(join("/", compact([
        yamldecode(v).apiVersion, 
        yamldecode(v).kind, 
        lookup(yamldecode(v).metadata, "namespace", ""), 
        yamldecode(v).metadata.name
      ]))) => v
  }
  yaml_body = each.value
}
