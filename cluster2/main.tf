terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}


provider "kubernetes" {
  config_path = "kubeconfig2"
}

resource "kubernetes_deployment" "cluster2" {
  metadata {
    name = "nginx-west"
    labels = {
      test = "west"
      app  = "nginx"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          image = "nginx"
          name  = "nginx"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "cluster2" {
  metadata {
    name = "nginx-west"
    labels = {
      test = "west"
      app  = "nginx"
    }
  }
  spec {
    selector = {
      app = kubernetes_deployment.CBC.spec.0.template.0.metadata.0.labels.app
    }
    type = "LoadBalancer"
    port {
      port = 80
    }
  }
}
