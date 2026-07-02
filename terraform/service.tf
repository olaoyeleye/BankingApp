resource "kubernetes_service_v1" "bank_frontend" {
  metadata {
    name      = "bank-frontend"
    namespace = "banking"
    labels = {
      app = "bank-frontend"
    }
  }

  spec {
    selector = {
      app = "bank-frontend"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 3000
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}