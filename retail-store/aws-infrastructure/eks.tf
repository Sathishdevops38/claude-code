# Kubernetes Namespaces
resource "kubernetes_namespace" "retail" {
  metadata {
    name = "retail-store"
    labels = {
      name = "retail-store"
    }
  }

  depends_on = [aws_eks_cluster.main]
}

# ConfigMap for Database Configuration
resource "kubernetes_config_map" "database_config" {
  metadata {
    name      = "database-config"
    namespace = kubernetes_namespace.retail.metadata[0].name
  }

  data = {
    "DB_HOST"     = aws_db_instance.main.address
    "DB_PORT"     = "3306"
    "DB_USER"     = var.db_username
    "DB_DATABASE" = "retaildb"
  }

  depends_on = [kubernetes_namespace.retail]
}

# Secret for Database Password
resource "kubernetes_secret" "database_password" {
  metadata {
    name      = "database-password"
    namespace = kubernetes_namespace.retail.metadata[0].name
  }

  data = {
    "DB_PASSWORD" = base64encode(var.db_password)
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace.retail]
}

# Service Account for Services
resource "kubernetes_service_account" "retail_services" {
  metadata {
    name      = "retail-services"
    namespace = kubernetes_namespace.retail.metadata[0].name
  }

  depends_on = [kubernetes_namespace.retail]
}

# Auth Service Deployment
resource "kubernetes_deployment" "auth_service" {
  metadata {
    name      = "auth-service"
    namespace = kubernetes_namespace.retail.metadata[0].name
    labels = {
      app = "auth-service"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "auth-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "auth-service"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.retail_services.metadata[0].name

        container {
          image = "${aws_ecr_repository.services["auth-service"].repository_url}:latest"
          name  = "auth-service"

          port {
            container_port = 8081
          }

          env {
            name = "SPRING_DATASOURCE_URL"
            value = "jdbc:mysql://${aws_db_instance.main.endpoint}:3306/retaildb"
          }

          env {
            name = "SPRING_DATASOURCE_USERNAME"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.database_config.metadata[0].name
                key  = "DB_USER"
              }
            }
          }

          env {
            name = "SPRING_DATASOURCE_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.database_password.metadata[0].name
                key  = "DB_PASSWORD"
              }
            }
          }

          resources {
            requests = {
              cpu    = "256m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "512m"
              memory = "1Gi"
            }
          }

          liveness_probe {
            http_get {
              path   = "/api/auth"
              port   = 8081
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path   = "/api/auth"
              port   = 8081
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.retail,
    kubernetes_config_map.database_config,
    kubernetes_secret.database_password
  ]
}

# Auth Service
resource "kubernetes_service" "auth_service" {
  metadata {
    name      = "auth-service"
    namespace = kubernetes_namespace.retail.metadata[0].name
  }

  spec {
    selector = {
      app = kubernetes_deployment.auth_service.metadata[0].labels.app
    }

    port {
      port        = 8081
      target_port = 8081
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.auth_service]
}

# Product Service Deployment
resource "kubernetes_deployment" "product_service" {
  metadata {
    name      = "product-service"
    namespace = kubernetes_namespace.retail.metadata[0].name
    labels = {
      app = "product-service"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "product-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "product-service"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.retail_services.metadata[0].name

        container {
          image = "${aws_ecr_repository.services["product-service"].repository_url}:latest"
          name  = "product-service"

          port {
            container_port = 8082
          }

          env {
            name = "DB_HOST"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.database_config.metadata[0].name
                key  = "DB_HOST"
              }
            }
          }

          env {
            name = "DB_USER"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.database_config.metadata[0].name
                key  = "DB_USER"
              }
            }
          }

          env {
            name = "DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.database_password.metadata[0].name
                key  = "DB_PASSWORD"
              }
            }
          }

          env {
            name  = "DB_NAME"
            value = "retaildb"
          }

          env {
            name  = "PORT"
            value = "8082"
          }

          resources {
            requests = {
              cpu    = "256m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "512m"
              memory = "1Gi"
            }
          }

          liveness_probe {
            http_get {
              path   = "/api/products"
              port   = 8082
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path   = "/api/products"
              port   = 8082
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.retail,
    kubernetes_config_map.database_config,
    kubernetes_secret.database_password
  ]
}

# Product Service
resource "kubernetes_service" "product_service" {
  metadata {
    name      = "product-service"
    namespace = kubernetes_namespace.retail.metadata[0].name
  }

  spec {
    selector = {
      app = kubernetes_deployment.product_service.metadata[0].labels.app
    }

    port {
      port        = 8082
      target_port = 8082
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.product_service]
}

# Order Service Deployment
resource "kubernetes_deployment" "order_service" {
  metadata {
    name      = "order-service"
    namespace = kubernetes_namespace.retail.metadata[0].name
    labels = {
      app = "order-service"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "order-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "order-service"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.retail_services.metadata[0].name

        container {
          image = "${aws_ecr_repository.services["order-service"].repository_url}:latest"
          name  = "order-service"

          port {
            container_port = 8083
          }

          env {
            name = "SPRING_DATASOURCE_URL"
            value = "jdbc:mysql://${aws_db_instance.main.endpoint}:3306/retaildb"
          }

          env {
            name = "SPRING_DATASOURCE_USERNAME"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.database_config.metadata[0].name
                key  = "DB_USER"
              }
            }
          }

          env {
            name = "SPRING_DATASOURCE_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.database_password.metadata[0].name
                key  = "DB_PASSWORD"
              }
            }
          }

          resources {
            requests = {
              cpu    = "256m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "512m"
              memory = "1Gi"
            }
          }

          liveness_probe {
            http_get {
              path   = "/api/orders"
              port   = 8083
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path   = "/api/orders"
              port   = 8083
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.retail,
    kubernetes_config_map.database_config,
    kubernetes_secret.database_password
  ]
}

# Order Service
resource "kubernetes_service" "order_service" {
  metadata {
    name      = "order-service"
    namespace = kubernetes_namespace.retail.metadata[0].name
  }

  spec {
    selector = {
      app = kubernetes_deployment.order_service.metadata[0].labels.app
    }

    port {
      port        = 8083
      target_port = 8083
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.order_service]
}

# Payment Service Deployment
resource "kubernetes_deployment" "payment_service" {
  metadata {
    name      = "payment-service"
    namespace = kubernetes_namespace.retail.metadata[0].name
    labels = {
      app = "payment-service"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "payment-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "payment-service"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.retail_services.metadata[0].name

        container {
          image = "${aws_ecr_repository.services["payment-service"].repository_url}:latest"
          name  = "payment-service"

          port {
            container_port = 8084
          }

          env {
            name = "DB_HOST"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.database_config.metadata[0].name
                key  = "DB_HOST"
              }
            }
          }

          env {
            name = "DB_USER"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.database_config.metadata[0].name
                key  = "DB_USER"
              }
            }
          }

          env {
            name = "DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.database_password.metadata[0].name
                key  = "DB_PASSWORD"
              }
            }
          }

          env {
            name  = "DB_NAME"
            value = "retaildb"
          }

          env {
            name  = "PORT"
            value = "8084"
          }

          resources {
            requests = {
              cpu    = "256m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "512m"
              memory = "1Gi"
            }
          }

          liveness_probe {
            http_get {
              path   = "/api/payments/health"
              port   = 8084
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path   = "/api/payments/health"
              port   = 8084
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.retail,
    kubernetes_config_map.database_config,
    kubernetes_secret.database_password
  ]
}

# Payment Service
resource "kubernetes_service" "payment_service" {
  metadata {
    name      = "payment-service"
    namespace = kubernetes_namespace.retail.metadata[0].name
  }

  spec {
    selector = {
      app = kubernetes_deployment.payment_service.metadata[0].labels.app
    }

    port {
      port        = 8084
      target_port = 8084
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.payment_service]
}

# API Gateway Ingress
resource "kubernetes_ingress_v1" "api_gateway" {
  metadata {
    name      = "api-gateway"
    namespace = kubernetes_namespace.retail.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"       = "alb"
      "alb.ingress.kubernetes.io/scheme"  = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
    }
  }

  spec {
    rule {
      host = "api.retail-store.local"

      http {
        path {
          path      = "/auth"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.auth_service.metadata[0].name
              port {
                number = 8081
              }
            }
          }
        }

        path {
          path      = "/products"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.product_service.metadata[0].name
              port {
                number = 8082
              }
            }
          }
        }

        path {
          path      = "/orders"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.order_service.metadata[0].name
              port {
                number = 8083
              }
            }
          }
        }

        path {
          path      = "/payments"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.payment_service.metadata[0].name
              port {
                number = 8084
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_service.auth_service,
    kubernetes_service.product_service,
    kubernetes_service.order_service,
    kubernetes_service.payment_service
  ]
}

# Horizontal Pod Autoscaler for Auth Service
resource "kubernetes_horizontal_pod_autoscaler_v2" "auth_service" {
  metadata {
    name      = "auth-service-hpa"
    namespace = kubernetes_namespace.retail.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.auth_service.metadata[0].name
    }

    min_replicas = 2
    max_replicas = 10

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }
  }

  depends_on = [kubernetes_deployment.auth_service]
}

# Horizontal Pod Autoscaler for Product Service
resource "kubernetes_horizontal_pod_autoscaler_v2" "product_service" {
  metadata {
    name      = "product-service-hpa"
    namespace = kubernetes_namespace.retail.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.product_service.metadata[0].name
    }

    min_replicas = 2
    max_replicas = 10

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }
  }

  depends_on = [kubernetes_deployment.product_service]
}

# Horizontal Pod Autoscaler for Order Service
resource "kubernetes_horizontal_pod_autoscaler_v2" "order_service" {
  metadata {
    name      = "order-service-hpa"
    namespace = kubernetes_namespace.retail.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.order_service.metadata[0].name
    }

    min_replicas = 2
    max_replicas = 10

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }
  }

  depends_on = [kubernetes_deployment.order_service]
}

# Horizontal Pod Autoscaler for Payment Service
resource "kubernetes_horizontal_pod_autoscaler_v2" "payment_service" {
  metadata {
    name      = "payment-service-hpa"
    namespace = kubernetes_namespace.retail.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.payment_service.metadata[0].name
    }

    min_replicas = 2
    max_replicas = 10

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }
  }

  depends_on = [kubernetes_deployment.payment_service]
}
