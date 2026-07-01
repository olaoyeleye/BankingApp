resource "kubernetes_ingress_v1" "banking" {
  metadata {
    name      = "banking-ingress"
    namespace = kubernetes_namespace_v1.banking.metadata[0].name

    annotations = {
      "alb.ingress.kubernetes.io/scheme"       = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"  = "ip"
      "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\":80}]"
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      http {
        path {
          path      = "/users"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.user_service.metadata[0].name
              port {
                number = 8000
              }
            }
          }
        }

        path {
          path      = "/transactions"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.transaction_service.metadata[0].name
              port {
                number = 8080
              }
            }
          }
        }

        path {
          path      = "/activity"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.activity_service.metadata[0].name
              port {
                number = 8001
              }
            }
          }
        }

        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.bank_frontend.metadata[0].name
              port {
                number = 3000
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.aws_load_balancer_controller,
    kubernetes_service_v1.user_service,
    kubernetes_service_v1.transaction_service,
    kubernetes_service_v1.activity_service,
    kubernetes_service_v1.bank_frontend
  ]
}