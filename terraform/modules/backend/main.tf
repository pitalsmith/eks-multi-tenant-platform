resource "kubernetes_deployment_v1" "this" {
  metadata {
    name = var.name
    labels = {
      app = var.name
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = var.name
      }
    }

    template {
      metadata {
        labels = {
          app = var.name
        }
      }

      spec {
        container {
          name  = var.name
          image = var.image

          port {
            container_port = 80
          }
        }
      }
    }
  }
}