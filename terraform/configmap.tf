data "aws_s3_bucket_object" "banking_config" {
  bucket = "techbleat-bank-app"
  key    = "terraform_manifest/configmap.json"
}

locals {
  banking_config_data = jsondecode(data.aws_s3_bucket_object.banking_config.body)
}

resource "kubernetes_config_map_v1" "banking_config" {
  metadata {
    name      = "banking-config"
    namespace = kubernetes_namespace_v1.banking.metadata[0].name
  }

  data = local.banking_config_data
}