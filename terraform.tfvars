k8s_version = "1.26"
#####CLUSTER 1 Settings###############
label = "us-east-k8s-3"
region = "us-east"
#Mark the following true for HA control plane or false for non-HA
HA = false
pools = {
  "pool-1" = {
    type = "g6-standard-1"
    min-nodes = 2
    max-nodes = 2
  }
}
############CLUSTER 2 Settings###########
label2 = "us-west-k8s-3"
region2 = "us-west"
#Mark the following true for HA control plane or false for non-HA
HA2 = false
pools2 = {
  "pool-2" = {
    type2 = "g6-standard-1"
    min-nodes2 = 1
    max-nodes2 = 3
  }
}
