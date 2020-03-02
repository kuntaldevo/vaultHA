#!/usr/bin/env bash
# B A S H ! ! !

# Set and environment variable that allows other scripts to know the main relative context
# Only relative path we will code for.  Once we have the project_root we can use full paths
source ~/.vault.d/vault-env.sh

####################################
#   Managing the arguments provided
####################################

function bail() {
  cat << EOF
usage: $0 -r|h [value] -k [value] -n [value] -s [value]
Options:
-h                       : print help message and exit
-r <region>              : use the given aws region e.g. us-east-1 instead of the default "us-west-2"
-k <k8s cluster name>    : name of the kubernetes cluster would like to be authorized with the Vault
-s <k8s service account> : name of the kubernetes service account (belongs to the kubernetes cluster) to be authorized. default is "vault-auth-<k8s cluster name>".
-n <k8s namespace>       : kubernetes namespace to which the service account will be maintained. default is "default" namespace.
EOF
  echo $1
  exit 1
}

while [ $# -gt 0 ]; do
  while getopts ":r:k:n:s:h" arg; do
    case "${arg}" in
      h)
        bail
        ;;
      r)
        K8s_Region="${OPTARG}"
        ;;
      k)
        K8s_ClusterName="${OPTARG}"
        ;;
      n)
        K8s_Namespace="${OPTARG}"
        ;;
      s)
        K8s_ServiceAccount="${OPTARG}"
        ;;
    esac
  done
  shift $((OPTIND-1))
done

# if the K8s Cluster details are not provided, the script should stop proceeding further
if [[ -z ${K8s_ClusterName} ]]; then
  echo "K8s ClusterName is a mandatory parameter for the script to proceed!!!!!"
  echo "Please check the details with '-h' option for help menu"
  echo ""
  bail
  echo ""
  exit 0
fi


#################################################
#   Populate the Kubernetes related parameters
#################################################

echo "Evaluating & Populating the Kubernetes related parameters"

# Populating the Kubernetes cluster details taken through command line
K8s_Region=`[ ${K8s_Region} ] && (echo ${K8s_Region}) || (echo "us-west-2")`

# Check if the K8s cluster exists in the region mentioned. If it doesn;t exits the script should stop proceeding further
K8s_ClusterName_Existing=`aws eks list-clusters --region ${K8s_Region} | grep ${K8s_ClusterName} | awk -F '"' {'print $2'}`
if [[ ${K8s_ClusterName_Existing} != ${K8s_ClusterName} ]];then
  echo "The K8s Cluster with name ${K8s_ClusterName} doesn't exists in the region ${K8s_Region}!!!"
  echo "Please check the K8s Clustername once again & retry with proper name. Exiting ... :-( :-("
  echo ""
  bail
  echo ""
  exit 0
fi

# The Service account to be used to authorize with the Vault
K8s_ServiceAccount=`[ ${K8s_ServiceAccount} ] && (echo ${K8s_ServiceAccount}) || (echo "vault-auth-"${K8s_ClusterName})`

# The Serviceaccount belongs to which Namespace, default is 'default'
K8s_Namespace=`[ ${K8s_Namespace} ] && (echo ${K8s_Namespace}) || (echo "default")`

# The port of the API server, default is set to 443
K8s_API_Port=`[ ${K8s_API_Port} ] && (echo ${K8s_API_Port}) || (echo "443")`

# Set Confiure the EKS cluster in Kubectl
aws eks update-kubeconfig --name ${K8s_ClusterName} --region ${K8s_Region} --profile default

if [[ $? -ne 0 ]];then
  echo "Some error in this step!!!!! Please check"
  echo "Exiting now...!!! :-( :-("
  exit 1
fi

echo "DONE :-) :-)"
echo ""


####################################################################################
#   Create K8s Cluster specific folder to store the policy & role specific files
####################################################################################
echo "Creating K8s Cluster specific folder to store the policy & role specific files"
DIR="./${K8s_ClusterName}/"
echo $DIR
if [[ -d "${DIR}" ]]; then
  echo ""
else
  mkdir ${DIR}
fi

####################################
#   Create the role binding yaml
####################################

echo "Create the role binding yaml"

cat <<EOF >> ./${DIR}/${K8s_ServiceAccount}-ServiceAccount-RoleBinding.yml
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: role-tokenreview-binding
  namespace: ${K8s_Namespace}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: ${K8s_ServiceAccount}
  namespace: ${K8s_Namespace}
EOF

if [[ $? -ne 0 ]];then
  echo "Some error in this step!!!!! Please check"
  echo "Exiting now...!!! :-( :-("
  exit 1
fi
echo "DONE :-) :-)"
echo ""


####################################
#   Create service account
####################################

# Create the  service account if it does not exist

echo "Creating Service account ${K8s_ServiceAccount}"
Existing_K8S_ServiceAccount=$(kubectl -n ${K8s_Namespace} get serviceaccount | grep "${K8s_ServiceAccount} " | awk {'print $1'} )
if [[ "${Existing_K8S_ServiceAccount}" == "${K8s_ServiceAccount}" ]];  then
  echo "Service account with name ${Existing_K8S_ServiceAccount} already exists !!!"
  echo "The same Service Account ${Existing_K8S_ServiceAccount} to be used. :-) :-)"
else
  kubectl -n ${K8s_Namespace} create serviceaccount ${K8s_ServiceAccount}
fi

if [[ $? -ne 0 ]];then
  echo "Some error in this step!!!!! Please check"
  echo "Exiting now...!!! :-( :-("
  exit 1
fi
echo "DONE :-) :-)"
echo ""


####################################
#   Update the  service account
####################################

echo "Creating role binding for Service Account ${K8s_ServiceAccount}"
kubectl apply --filename ${DIR}/${K8s_ServiceAccount}-ServiceAccount-RoleBinding.yml

if [[ $? -ne 0 ]];then
  echo "Some error in this step!!!!! Please check"
  echo "Exiting now...!!! :-( :-("
  exit 1
fi

echo "DONE :-) :-)"
echo ""


####################################
#   Get account secret Name
####################################

echo "Get account secret Name"

Vault_SA_SecretName=$(kubectl -n ${K8s_Namespace} get sa ${K8s_ServiceAccount} -o jsonpath="{.secrets[*]['name']}")

if [[ $? -ne 0 ]];then
  echo "Some error in this step!!!!! Please check"
  echo "Exiting now...!!! :-( :-("
  exit 1
fi

echo "DONE :-) :-)"
echo ""


####################################################
#   Get JWT Token  to access the TokenReview API
####################################################

echo "Get JWT Token  to access the TokenReview API"

JWT_Token=$(kubectl -n ${K8s_Namespace} get secret ${Vault_SA_SecretName} -o jsonpath='{.data.token}' | base64 --decode)

if [[ $? -ne 0 ]];then
  echo "Some error in this step!!!!! Please check"
  echo "Exiting now...!!! :-( :-("
  exit 1
fi
echo "DONE :-) :-)"
echo ""


########################################################
#   Get CA-certificate used to talk to Kubernetes API
########################################################

echo "Get CA-certificate used to talk to Kubernetes API"

SA_CA_Certificate=$(kubectl -n ${K8s_Namespace} get secret ${Vault_SA_SecretName} -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)

if [[ $? -ne 0 ]];then
  echo "Some error in this step!!!!! Please check"
  echo "Exiting now...!!! :-( :-("
  exit 1
fi

echo "DONE :-) :-)"
echo ""


###################################
#   Set K8s API Server Details
###################################

echo "Set K8s API Server Details"

K8s_API_Host=$(kubectl config view --minify | grep server | awk {'print $2'})
K8s_API_URL=${K8s_API_Host}:${K8s_API_Port}

if [[ $? -ne 0 ]];then
  echo "Some error in this step!!!!! Please check"
  echo "Exiting now...!!! :-( :-("
  exit 1
fi
echo "DONE :-) :-)"
echo ""


###################################
#   Login to the Vault
###################################

echo "Log in to the vault"
vault login -no-print $VAULT_TOKEN 2>&1

if [[ $? -ne 0 ]];then
  echo "Some error in this step!!!!! Please check"
  echo "Exiting now...!!! :-( :-("
  exit 1
fi
echo "DONE :-) :-)"
echo ""


#############################################
#   Adding Kubernetes auth into the Vault
#############################################

echo "Configuring Vault for Kubernetes"

# Enable the Kubernetes auth backend in the vault if not already enabled
KUBERNETES=$(vault auth list | grep kubernetes | grep ${K8s_ClusterName} | awk -F "/" {'print $1'})
if [[ ${KUBERNETES} == ${K8s_ClusterName} ]];  then
  echo "kubernetes auth is already ENABLED for K8s Cluster ${K8s_ClusterName}"
else
  vault auth enable -path=${K8s_ClusterName} kubernetes
fi

if [[ $? -ne 0 ]];then
  echo "Some error in this step!!!!! Please check"
  echo "Exiting now...!!! :-( :-("
  exit 1
fi
echo "DONE :-) :-)"
echo ""


#####################################################
#   Authenticate the Service Account into Vault
#####################################################

echo "Authenticate the Service Account ${K8s_ServiceAccount} into Vault"

vault write auth/${K8s_ClusterName}/config kubernetes_host=${K8s_API_URL} kubernetes_ca_cert="${SA_CA_Certificate}" token_reviewer_jwt="${JWT_Token}"

if [[ $? -ne 0 ]];then
  echo "Some error in this step!!!!! Please check"
  echo "Exiting now...!!! :-( :-("
  exit 1
fi
echo "DONE :-) :-)"
echo ""

######################################################################
#   Set Policy name as the cluster name: Region : service account
######################################################################

POLICY_NAME=${K8s_Region}:${K8s_ClusterName}:${K8s_ServiceAccount}


#######################################################################
#   Creating the Policy file for the Service Account to Authorize
#######################################################################

echo Creating policy file
cat <<EOF > ${DIR}/policy.hcl
path "secret/k8s/*" {
 capabilities = ["read", "list"]
}
path "secret/data/k8s/*" {
 capabilities = ["read", "list"]
}
path "sys/mounts" {
 capabilities = ["read"]
}
EOF

if [[ $? -ne 0 ]];then
  echo "Some error in this step!!!!! Please check"
  echo "Exiting now...!!! :-( :-("
  exit 1
fi
echo "DONE :-) :-)"
echo ""

################################################################################
#   Create a new policy demo-policy using an example policy file policy.hcl
################################################################################

echo Creating policy in vault
vault write sys/policy/${POLICY_NAME} policy=@${DIR}/policy.hcl

if [[ $? -ne 0 ]];then
  echo "Some error in this step!!!!! Please check"
  echo "Exiting now...!!! :-( :-("
  exit 1
fi
echo "DONE :-) :-)"
echo ""

##################################################################
#   create a role for binding the policy to a service account.
##################################################################

echo "Creating role and binding it to policy"
vault write auth/${K8s_ClusterName}/role/K8s-role \
 bound_service_account_names=${K8s_ServiceAccount} \
 bound_service_account_namespaces=${K8s_Namespace} \
 policies=${POLICY_NAME}

if [[ $? -ne 0 ]];then
  echo "Some error in this step!!!!! Please check"
  echo "Exiting now...!!! :-( :-("
  exit 1
fi

echo "DONE :-) :-)"
echo ""

# This is just for testing if the user got created successfully
#vault write auth/${K8s_ClusterName}/login -path=${K8s_ClusterName} role=K8s-role jwt="$JWT_Token"
