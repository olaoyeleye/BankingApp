#resource "helm_release" "ingress_nginx" {
#  name             = "ingress-nginx"
#  repository       = "https://kubernetes.github.io/ingress-nginx"
#  chart            = "ingress-nginx"
#  namespace        = "ingress-nginx"
#  create_namespace = true

#  timeout          = 900
#  wait             = true
#  cleanup_on_fail  = true
#  atomic           = false

#  values = [yamlencode({
#    controller = {
#      service = {
#        type = "LoadBalancer"
#      }
#    }
#  })]

#  depends_on = [
#    aws_eks_node_group.main
#  ]
#}

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  timeout          = 900

  values = [yamlencode({
    controller = {
      service = {
        type = "NodePort"
      }
    }
  })]

  depends_on = [
    aws_eks_node_group.main
  ]
}