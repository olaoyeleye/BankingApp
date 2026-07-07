#resource "kubernetes_service_v1" "bank_frontend" {
#  metadata {
#    name      = "banking"
#    namespace = kubernetes_namespace_v1.banking.metadata[0].name
#    labels = {
#      app = "bank-frontend"
#    }
#  }

#  spec {
#    selector = {
#      app = "bank-frontend"
#    }

#    port {
#      name        = "http"
#      port        = 80
#      target_port = 3000
#      protocol    = "TCP"
#    }

#    type = "ClusterIP"
#  }
  
#  depends_on = [kubernetes_namespace_v1.banking]

#}


resource "kubernetes_namespace_v1" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "kubernetes_namespace_v1" "banking" {
  metadata {
    name = "banking"
  }
}

resource "kubernetes_service_v1" "bank_frontend" {
  metadata {
    name      = "banking"
    namespace = kubernetes_namespace_v1.banking.metadata[0].name
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
  
  depends_on = [kubernetes_namespace_v1.banking]

}