resource "kubernetes_storage_class_v1" "gp2" {
  metadata {
    name = "gp2"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type   = "gp2"
    fsType = "ext4"
  }

  depends_on = [helm_release.ebs_csi_driver]
}

resource "kubernetes_persistent_volume_claim_v1" "postgres_pvc" {
  metadata {
    name      = "postgres-pvc"
    namespace = kubernetes_namespace_v1.banking.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = kubernetes_storage_class_v1.gp2.metadata[0].name

    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }
}