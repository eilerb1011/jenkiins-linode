# jenkiins-linode
Linode LKE from Jenkins
## SAMPLE PIPELINE
```
pipeline {
    agent any
    
    environment {
        TF_VAR_token = credentials('[INSERT YOUR credential ID in Jenkins for Linode]')
        TF_VAR_workspace="${WORKSPACE}"
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', credentialsId: '[INSERT YOUR credential ID in Jenkins for Giuthub]', url: 'https://github.com/eilerb1011/jenkins-linode'
            }
        }
        stage('Terraform init') {
            steps {
                sh 'terraform init'
            }
        }
        stage('Terraform apply') {
            steps {
                sh 'terraform apply --auto-approve'
                   //write the template output in a file
                sh 'rm -f ${WORKSPACE}/cluster1/kubeconfig1.yaml'
                sh 'rm -f ${WORKSPACE}/cluster2/kubeconfig2.yaml'
                sh 'terraform output -raw kubeconfig1 >> ${WORKSPACE}/cluster1/kubeconfig1.yaml'
                sh 'terraform output -raw kubeconfig2 >> ${WORKSPACE}/cluster2/kubeconfig2.yaml'
                
            }
        }
        stage('k8s-east-deploy-init') {
            steps {
                sh 'terraform -chdir=${WORKSPACE}/cluster1/ init'
            }
        }
        stage('k8s-east-deploy') {
            steps {
                sh 'terraform -chdir=${WORKSPACE}/cluster1/ apply --auto-approve'
            }
        }
            stage('k8s-west-deploy-init') {
            steps {
                sh 'terraform -chdir=${WORKSPACE}/cluster2/ init'
            }
        }
        stage('k8s-west-deploy') {
            steps {
                sh 'terraform -chdir=${WORKSPACE}/cluster2/ apply --auto-approve'
            }
        }
    }
}
```
