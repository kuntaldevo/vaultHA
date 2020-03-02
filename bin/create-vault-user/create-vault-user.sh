#!/usr/bin/env bash

set -o allexport
source ./vault-env.sh
set +o allexport

####################################
#   Managing the arguments provided
####################################

function bail() {
  cat << EOF
usage: $0 -s|h [value] -u [value] -p [value]
Options:
-h                  : print help message and exit
-s <secret path>    : logical path to which the secrets will be stored for the same user. default is "secret"
-u <username>       : username of the user for which the login is created
-p <password>       : password for the user. default is "password"
EOF
  echo $1
  exit 1
}

#POSITIONAL_ARGS=""
while [ $# -gt 0 ]; do
  while getopts ":s:p:u:h" arg; do
    case "${arg}" in
      h)
        bail
        ;;
      s)
        SECRET_PATH="${OPTARG}"
        ;;
      u)
        USERNAME="${OPTARG}"
        ;;
      p)
        PASSWORD="${OPTARG}"
        ;;
    esac
  done
  shift $((OPTIND-1))
done


# if the username is not provided, the script should stop proceeding further
if [[ -z ${USERNAME} ]]; then
  echo "username is a mandatory parameter for the script to proceed!!!!!"
  echo "Please check the details with '-h' option for help menu"
  exit 0
fi


#################################################
#   Populate the Kubernetes related parameters
#################################################

echo "Populate the user related parameters"

# Populating the user details taken through command line
SECRET_PATH=`[ ${SECRET_PATH} ] && (echo ${SECRET_PATH}) || (echo "secret")`
PASSWORD=`[ ${PASSWORD} ] && (echo ${PASSWORD}) || (echo "password")`


############################
#  Vault Login
############################

echo "Loggin into the vault"
vault login -no-print $VAULT_TOKEN 2>null

if [[ $? -ne 0 ]];then
  echo "Some error in this step!!!!! Please check"
  echo "Exiting now...!!! :-( :-("
  exit 1
fi

echo "DONE :-) :-)"
echo ""


#################################################################
#  Enable Secret plugin to store secrets into a specific path
#################################################################

echo "***Enable the secret database for the secret engine***"
echo "***vault secrets enable -path=${SECRET_PATH} kv***"

if [[ $(vault secrets list | awk {'print $1'} | grep secret | awk -F "/" {'print $1'}) ]];then
  echo "secret engine is already enabled!!!!"
else
  vault secrets enable -path=${SECRET_PATH} kv
fi

if [[ $? -ne 0 ]];then
  echo "Some error in this step!!!!! Please check"
  echo "Exiting now...!!! :-( :-("
  exit 1
fi

echo "DONE :-) :-)"
echo ""


##########################################################
#  Enabling Vault Authorization with USERPASS engine
##########################################################

echo "***Enabling Vault Authorization for USERPASS***"
echo "***vault auth enable userpass***"

USERPASS=$(vault auth list | grep userpass | awk '{print $2'})
if [[ ${USERPASS} == "userpass" ]];  then
  echo "userpass auth is already ENABLED"
else
  vault auth enable userpass
fi

if [[ $? -ne 0 ]];then
  echo "Some error in this step!!!!! Please check"
  echo "Exiting now...!!! :-( :-("
  exit 1
fi
echo "DONE :-) :-)"
echo ""


#########################################################
#  Create required vault access policy file for the user
#########################################################

echo "Creating the policy file for the vault user"

POLICY_FILE_NAME="vault-${USERNAME}-access.hcl"
cat <<EOF >> ${POLICY_FILE_NAME}
path "secret/k8s/${USERNAME}/*" {
    capabilities = ["read", "list", "create", "delete"]
}
path "secret/${USERNAME}/*" {
    capabilities = ["read", "list", "create" , "delete"]
}
path "secret/common/*" {
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


#########################################################
#  Applying required vault access policy for the user
#########################################################

echo "***Creating user specific policy using policy file***"
echo "***vault policy write ${USERNAME} ${POLICY_FILE_NAME}***"

vault policy write ${USERNAME}-policy ${POLICY_FILE_NAME}

if [[ $? -ne 0 ]];then
  echo "Some error in this step!!!!! Please check"
  echo "Exiting now...!!! :-( :-("
  exit 1
fi

echo "DONE :-) :-)"
echo ""


################################################
#  Creating vault user attaching the policy
################################################

echo "*Creating vault user attaching the policy*"
echo "****vault write auth/userpass/users/${USERNAME} password=${PASSWORD} policies=${USERNAME}-policy"

vault write auth/userpass/users/${USERNAME} password=${PASSWORD} policies=${USERNAME}-policy

if [[ $? -ne 0 ]];then
  echo "Some error in this step!!!!! Please check"
  echo "Exiting now...!!! :-( :-("
  exit 1
fi

echo "DONE :-) :-)"
echo ""


################################################
#  Login into vault with user credentials
################################################

echo "*Checking Log in to the vault for the specific user"
echo "***vault login -method=userpass username=${USERNAME} password=${PASSWORD}***"
vault login -method=userpass username=${USERNAME} password=${PASSWORD} 2>null

if [[ $? -ne 0 ]];then
  echo "Some error in this step!!!!! Please check"
  echo "Exiting now...!!! :-( :-("
  exit 1
fi

echo "DONE :-) :-)"
echo ""
