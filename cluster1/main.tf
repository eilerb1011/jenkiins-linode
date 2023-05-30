terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

provider "kubernetes" {
  config_path = "${var.workspace}/cluster1/kubeconfig1.yaml"
}
resource "kubernetes_deployment" "cluster1" {
  metadata {
    name = "nginx-east"
    labels = {
      test = "east"
      app  = "nginx"
    }
  }

  spec {
    replicas = 1

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
          image = "stenote/nginx-hostname"
          name  = "nginx"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "cluster1" {
  metadata {
    name = "nginx-east"
    labels = {
      test = "east"
      app  = "nginx"
    }
  }
  spec {
    selector = {
      app = kubernetes_deployment.cluster1.spec.0.template.0.metadata.0.labels.app
    }
    type = "LoadBalancer"
    port {
      port = 80
    }
  }
}

output "load_balancer_ip" {
  value = kubernetes_service.cluster1.status.0.load_balancer.0.ingress.0.ip
}
