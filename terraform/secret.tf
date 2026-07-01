data "aws_s3_object" "banking_secrets" {
  bucket = "techbleat-bank-app"
  key    = "terraform_manifest/secret.json"
}

locals {
  banking_secret_data = jsondecode(data.aws_s3_object.banking_secrets.body)
}

resource "kubernetes_secret_v1" "banking_secrets" {
  metadata {
    name      = "banking-secrets"
    namespace = kubernetes_namespace_v1.banking.metadata[0].name
  }

  type = "Opaque"
  data = local.banking_secret_data
}