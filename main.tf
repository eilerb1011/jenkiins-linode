terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "1.27.1"
    }
  }
}
//Use the Linode Provider
provider "linode" {
  token = var.token
}

//Use the linode_lke_cluster resource to create
//a Kubernetes cluster
resource "linode_lke_cluster" "cluster1" {
  k8s_version = var.k8s_version
  label       = var.label
  region      = var.region
  control_plane  {
        high_availability = var.HA
    }
  dynamic "pool" {
    for_each = var.pools
    content {
      type  = pool.value["type"]
      count = pool.value["min-nodes"]
      autoscaler {
        min = pool.value["min-nodes"]
        max = pool.value["max-nodes"]
        }
      }
    }
  }
resource "linode_lke_cluster" "cluster2" {
  k8s_version = var.k8s_version
  label       = var.label2
  region      = var.region2
  control_plane  {
        high_availability = var.HA2
    }
  dynamic "pool" {
    for_each = var.pools2
    content {
      type  = pool.value["type2"]
      count = pool.value["min-nodes2"]
      autoscaler {
        min = pool.value["min-nodes2"]
        max = pool.value["max-nodes2"]
        }
      }
    }
  }
#terraform {
#  backend "http" {
#  }
#}
output "kubeconfig1" {
  value     = linode_lke_cluster.cluster1.kubeconfig
  sensitive = true
}
output "kubeconfig2" {
  value     = linode_lke_cluster.cluster2.kubeconfig
  sensitive = true
}
