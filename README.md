# jenkiins-linode
## Linode LKE from Jenkins
This repo creates a simple multi-location managed Kubernetes deployment in Linode using Terraform, GitHub and Jenkins.  Overall it will create a terraform config for 2 LKE clusters in 2 DCs and deploy nginx to each and expose with CCM instantiated Cloud load balancers that will echo back a hostname, automated with Jenkins.  If you do not have a Jenkins server already, you can create one simply from the Linode Marketplace.  Below are instructions to set up Jenkins using SSL:

## Build Jenkins from Marketplace 
Using your Linode account, locate Jenkins in the Marketplace and follow the deployment instructions.
- Setup your dns name based on the IP assigned to the Jenkins server and create that A record in your authoritative DNS
- Login to your server via SSH or Linode's LISH console in the portal
- Get the initial Jenkins password from /var/lib/jenkins/secrets/initialpassword `cat /var/lib/jenkins/secrets/initialpassword`
- While in the server:
    
```
sudo apt update && sudo apt install -y git certbot 
certbot certonly --standalone 
```
Go through prompts, enter your domain, etc... 
```
Crontab –e
```
Add: 
```
0 0 */30 * * certbot renew
``` 
### **-----------------SETUP CERT AND JENKINS SSL------------------** 
First you must convert your cert to JKS format using openssl and keytool:  This example uses my a server at jenkins.mydomain.com
```
cd /etc/letsencrypt/live/jenkins.mydomain.com
cp cert.pem jenkins.mydomain.com.crt
cp privkey.pem jenkins.mydomain.com.key

openssl pkcs12 -export -out jenkins.p12 -passout 'pass:mycomplexpassword' -inkey jenkins.mydomain.com.key -in jenkins.mydomain.com.crt -name jenkins.mydomain.com
keytool -importkeystore -srckeystore jenkins.p12 -srcstorepass 'mycomplexpassword' -srcstoretype PKCS12 -srcalias jenkins.mydomain.com -destkeystore jenkins.jks -deststorepass 'myothercomplexpassword' -destalias jenkins.mydomain.com
systemctl edit jenkins --full
``` 
VERY IMPORTANT – JENKINS RUNS AS AN UNDER-PRIVILEDGED USER - YOU CANNOT USE PORTS UNDER 1024 
Find, uncomment and edit:
```
Environment="JENKINS_PORT=8080"
``` 
Change the port to –1 to disable HTTP 
Find, uncomment and edit:
```
Environment="JENKINS_HTTPS_PORT=443"
``` 
Change port to 8443 
Find, uncomment and edit:
```
Environment="JENKINS_HTTPS_KEYSTORE=/path/to/keystore"
```
This should reflect the path to your keystore created with keytool from above
AND
```
Environment="JENKINS_HTTPS_KEYSTORE_PASSWORD="
``` 
This should match the password you set to the destination keystore 
AND
```
Environment="JENKINS_HTTPS_LISTEN_ADDRESS="
``` 
Add 0.0.0.0 before the final quote 
Save & Exit 

Run 
```
systemctl daemon reload && systemctl restart jenkins
```

- Login to Jenkins at https://your.dnsname.com:8443 
- Setup your server with Dashboard and Github 
- Set up your first admin user 
- Set your URL
## Jenkins Plugins
First thing to do is to check for the Terraform and Git plugins by opening the Jenkins console, select Manage Jenkins and then Plugins.  Click Installed Plugins from the left hand navigation.  In the search, check for Git and Terraform and make sure each is enabled.  If you are missing one of these, go to Available plugins from the left hand navigation, seach for the Plugin, mark the checkbox next to Install and click the Install without restart button.

## Creating creds for Github in Jenkins:
Generate a PAT IN Github with the following permissions: 
- Repo 
- Admin:repo_hook 
- Delete_repo
  
Make note of the new key 
In Jenkins, select Manage Jenkins and System. 
In the GitHub section: 
Give your server a name (ie important if you have multiple GitHub Enterprise servers) 
If using github.com, leave the API URL at https://api.github.com 
Under credentials, 
- Add new credentials 
- Select Jenkins 
- Select kind = secret text and paste your Github PAT into the Secret field
- Give your secret a meaningful ID, else it will be assigned a random UID.  You will use this as the ID below to populate credentialsId in the Git commands of your script
   
After entering the new credentials, select it from the credentials drop down and click test connection. 
Then save the config 

## Creating creds for Linode/Terraform
- Create an Akamai Connected Cloud Personal Access Token from the Linode/Akamai Connected Cloud Console.
- Using that token you can create new credentials to be used in your deployment scripts by going to the Jenkins Dashboard and selecting Manage Jenkins and Credentials.  Now, if you click the down arrow next to Credentials at the top, you can select System.  Here is where you can either setup domains or set your credential as a Global.  For this exercise, click Global credentials. 
Under Global credentials, click
- Add new credentials 
- Select kind = secret text and then paste your Linode/Akamai token into the Secret field
- Give your secret a meaningful ID, else it will be assigned a random UID.  You will use this as the ID below to populate TF_VAR_token

## Create Your Pipeline
Set up your pipeline with a new pipeline script in the configuration.  you can set up triggers to kick off the build of a cluster if necessary in your environment.  Otherwise you can customize the script below with your credential information.  Then hit the build now to create the clusters and deploy the manifests.

### SAMPLE PIPELINE
```
pipeline {
    agent any
    
    environment {
        TF_VAR_token = credentials('[put your linode credentials id here]')
        TF_VAR_workspace="${WORKSPACE}"
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', credentialsId: '[put your credentials id here]', url: 'https://github.com/eilerb1011/jenkins-linode'
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
