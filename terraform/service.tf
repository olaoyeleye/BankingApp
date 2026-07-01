resource "kubernetes_namespace_v1" "banking" {
  metadata {
    name = "banking"
  }
}

resource "kubernetes_service_v1" "bank_frontend" {
  metadata {
    name      = "bank-frontend"
    namespace = kubernetes_namespace_v1.banking.metadata[0].name
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = "bank-frontend"
    }

    port {
      protocol    = "TCP"
      port        = 3000
      target_port = 3000
    }
  }
}

resource "kubernetes_service_v1" "user_service" {
  metadata {
    name      = "user-service"
    namespace = kubernetes_namespace_v1.banking.metadata[0].name
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = "user-service"
    }

    port {
      protocol    = "TCP"
      port        = 8000
      target_port = 8000
    }
  }
}

resource "kubernetes_service_v1" "transaction_service" {
  metadata {
    name      = "transaction-service"
    namespace = kubernetes_namespace_v1.banking.metadata[0].name
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = "transaction-service"
    }

    port {
      protocol    = "TCP"
      port        = 8080
      target_port = 8080
    }
  }
}

resource "kubernetes_service_v1" "activity_service" {
  metadata {
    name      = "activity-service"
    namespace = kubernetes_namespace_v1.banking.metadata[0].name
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = "activity-service"
    }

    port {
      protocol    = "TCP"
      port        = 8001
      target_port = 8001
    }
  }
}

resource "kubernetes_service_v1" "postgres_service" {
  metadata {
    name      = "postgres-service"
    namespace = kubernetes_namespace_v1.banking.metadata[0].name
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = "postgres"
    }

    port {
      protocol    = "TCP"
      port        = 5432
      target_port = 5432
    }
  }
}

resource "kubernetes_service_v1" "redis_service" {
  metadata {
    name      = "redis-service"
    namespace = kubernetes_namespace_v1.banking.metadata[0].name
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = "redis"
    }

    port {
      protocol    = "TCP"
      port        = 6379
      target_port = 6379
    }
  }
}

resource "kubernetes_service_v1" "kafka_service" {
  metadata {
    name      = "kafka-service"
    namespace = kubernetes_namespace_v1.banking.metadata[0].name
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = "kafka"
    }

    port {
      name        = "internal"
      protocol    = "TCP"
      port        = 29092
      target_port = 29092
    }

    port {
      name        = "external"
      protocol    = "TCP"
      port        = 9092
      target_port = 9092
    }

    port {
      name        = "jmx"
      protocol    = "TCP"
      port        = 9101
      target_port = 9101
    }

    port {
      name        = "controller"
      protocol    = "TCP"
      port        = 29093
      target_port = 29093
    }
  }
}