terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}


provider "kubernetes" {
  config_path = "${var.workspace}/cluster2/kubeconfig2.yaml"
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
      app = kubernetes_deployment.cluster2.spec.0.template.0.metadata.0.labels.app
    }
    type = "LoadBalancer"
    port {
      port = 80
    }
  }
}
output "load_balancer_ip2" {
  value = kubernetes_service.cluster2.status.0.load_balancer.0.ingress.0.ip
}
