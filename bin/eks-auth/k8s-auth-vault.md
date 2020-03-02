# Authorizing an EKS cluster with vault.

This code authorizes an EKS cluster to pull secrets from the vault. After authorization, all PODs in this cluster will have permission to list and read secrets from the path "secret/k8s/*"
This code does the following
 - Create a service account in the EKS called vault-auth-<K8s_ClusterName>
 - Create a role binding for this service account
 - Obtain the JW token and CA certificate for the cluster
 - Authorize all pods running in this cluster to read secrets in under "secrets/k8s"
 

# Prerequisites 
To run the script the following are the pre-requisites 
 - The EKS cluster should be up and running
 - The saml2aws login should done
 - The user should have proper access rights in the k8s cluster
  - The Vault must be up and running
 
 
 # Running the script
 Before running the script the  	vault-env.sh file needs to be updated with the correct value of VAULT_ADDR and VAULT_TOKEN
 
 The script accepts the following parameters
 
 -r <region>              : use the given aws region e.g. us-east-1 instead of the default "us-west-2"
 
 -k <k8s cluster name>    : name of the kubernetes cluster would like to be authorized with the Vault (MANDATORY)
 
 -s <k8s service account> : name of the kubernetes service account (belongs to the kubernetes cluster) to be authorized. default is "vault-auth-<k8s cluster name>".
 
 -n <k8s namespace>       : kubernetes namespace to which the service account will be maintained. default is "default" namespace
 
 e.g  ./k8s-auth-vault.sh -r us-east-1 -k sdey-eks 
 
