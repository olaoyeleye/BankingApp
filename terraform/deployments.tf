resource "kubernetes_config_map_v1" "postgres_init_sql" {
  metadata {
    name      = "postgres-init-sql"
    namespace = "banking"
  }

  data = {
    "init.sql" = <<-SQL
      CREATE TABLE IF NOT EXISTS users (
        id VARCHAR(50) PRIMARY KEY,
        full_name VARCHAR(100) NOT NULL,
        email VARCHAR(120) UNIQUE NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS accounts (
        user_id VARCHAR(50) PRIMARY KEY,
        balance NUMERIC(12,2) NOT NULL DEFAULT 0,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS transactions (
        id SERIAL PRIMARY KEY,
        user_id VARCHAR(50) NOT NULL,
        transaction_type VARCHAR(30) NOT NULL,
        amount NUMERIC(12,2) NOT NULL,
        reference VARCHAR(100),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS activities (
        id SERIAL PRIMARY KEY,
        user_id VARCHAR(50) NOT NULL,
        activity_type VARCHAR(50) NOT NULL,
        description TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    SQL
  }
}

resource "kubernetes_deployment_v1" "postgres" {
  metadata {
    name      = "postgres"
    namespace = "banking"
    labels = {
      app = "postgres"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }

      spec {
        container {
          name  = "postgres"
          image = var.postgres_image

          port {
            container_port = 5432
          }

          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }

          env {
            name = "POSTGRES_DB"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.banking_secrets.metadata[0].name
                key  = "POSTGRES_DB"
              }
            }
          }

          env {
            name = "POSTGRES_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.banking_secrets.metadata[0].name
                key  = "POSTGRES_USER"
              }
            }
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.banking_secrets.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          volume_mount {
            name       = "postgres-storage"
            mount_path = "/var/lib/postgresql/data"
          }

          volume_mount {
            name       = "init-sql"
            mount_path = "/docker-entrypoint-initdb.d/init.sql"
            sub_path   = "init.sql"
          }
        }

        volume {
          name = "postgres-storage"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.postgres_pvc.metadata[0].name
          }
        }

        volume {
          name = "init-sql"

          config_map {
            name = kubernetes_config_map_v1.postgres_init_sql.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment_v1" "redis" {
  metadata {
    name      = "redis"
    namespace = kubernetes_namespace_v1.banking.metadata[0].name
    labels = {
      app = "redis"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "redis"
      }
    }

    template {
      metadata {
        labels = {
          app = "redis"
        }
      }

      spec {
        container {
          name  = "redis"
          image = "redis:7"

          port {
            container_port = 6379
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment_v1" "kafka" {
  metadata {
    name      = "kafka"
    namespace = kubernetes_namespace_v1.banking.metadata[0].name
    labels = {
      app = "kafka"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "kafka"
      }
    }

    template {
      metadata {
        labels = {
          app = "kafka"
        }
      }

      spec {
        container {
          name  = "kafka"
          image = "confluentinc/cp-kafka:8.1.1"

          port { container_port = 9092 }
          port { container_port = 9101 }
          port { container_port = 29092 }
          port { container_port = 29093 }

          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.banking_config.metadata[0].name
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment_v1" "user_service" {
  metadata {
    name      = "user-service"
    namespace = kubernetes_namespace_v1.banking.metadata[0].name
    labels = {
      app = "user-service"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "user-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "user-service"
        }
      }

      spec {
        container {
          name  = "user-service"
          image = var.user_service_image

          port {
            container_port = 8000
          }

          env {
            name = "DATABASE_URL"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.banking_secrets.metadata[0].name
                key  = "DATABASE_URL"
              }
            }
          }

          env {
            name = "FRONTEND_ORIGIN"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.banking_config.metadata[0].name
                key  = "FRONTEND_ORIGIN"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment_v1" "transaction_service" {
  metadata {
    name      = "transaction-service"
    namespace = kubernetes_namespace_v1.banking.metadata[0].name
    labels = {
      app = "transaction-service"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "transaction-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "transaction-service"
        }
      }

      spec {
        container {
          name  = "transaction-service"
          image = var.transaction_service_image

          port {
            container_port = 8080
          }

          env {
            name = "SPRING_DATASOURCE_URL"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.banking_secrets.metadata[0].name
                key  = "SPRING_DATASOURCE_URL"
              }
            }
          }

          env {
            name = "SPRING_DATASOURCE_USERNAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.banking_secrets.metadata[0].name
                key  = "SPRING_DATASOURCE_USERNAME"
              }
            }
          }

          env {
            name = "SPRING_DATASOURCE_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.banking_secrets.metadata[0].name
                key  = "SPRING_DATASOURCE_PASSWORD"
              }
            }
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.banking_config.metadata[0].name
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment_v1" "activity_service" {
  metadata {
    name      = "activity-service"
    namespace = kubernetes_namespace_v1.banking.metadata[0].name
    labels = {
      app = "activity-service"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "activity-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "activity-service"
        }
      }

      spec {
        container {
          name  = "activity-service"
          image = var.activity_service_image

          port {
            container_port = 8001
          }

          env {
            name = "DATABASE_URL"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.banking_secrets.metadata[0].name
                key  = "DATABASE_URL"
              }
            }
          }

          env {
            name = "KAFKA_BOOTSTRAP_SERVERS"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.banking_config.metadata[0].name
                key  = "KAFKA_BOOTSTRAP_SERVERS"
              }
            }
          }

          env {
            name = "FRONTEND_ORIGIN"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.banking_config.metadata[0].name
                key  = "FRONTEND_ORIGIN"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment_v1" "bank_frontend" {
  metadata {
    name      = "bank-frontend"
    namespace = kubernetes_namespace_v1.banking.metadata[0].name
    labels = {
      app = "bank-frontend"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "bank-frontend"
      }
    }

    template {
      metadata {
        labels = {
          app = "bank-frontend"
        }
      }

      spec {
        container {
          name  = "bank-frontend"
          image = var.frontend_image

          port {
            container_port = 3000
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.banking_config.metadata[0].name
            }
          }
        }
      }
    }
  }
}