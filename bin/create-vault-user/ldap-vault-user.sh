#!/usr/bin/env bash

set -o allexport
source ~/.vault.d/vault-env.sh
set +o allexport

### Clean up any old Auth Tokens
rm -rf ~/.vault-token


error() {
  local parent_lineno="$1"
  local message="$2"
  local code="${3:-1}"
  if [[ -n "$message" ]] ; then
    echo "Error on or near line ${parent_lineno}: ${message}; exiting with status ${code}"
  else
    echo "Error on or near line ${parent_lineno}; exiting with status ${code}"
  fi
  exit "${code}"
}
trap 'error ${LINENO}' ERR


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
EOF
  echo $1
  exit 1
}

#POSITIONAL_ARGS=""
while [ $# -gt 0 ]; do
  while getopts ":s:u:h" arg; do
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
      *) echo "unrecognized argument: $1";  bail;;
    esac
  done
  shift $((OPTIND-1))
done


# if the username is not provided, the script should stop proceeding further
if [[ -z ${USERNAME} ]]; then
  echo "username is a mandatory parameter for the script to proceed!!!!!"
  echo "Please check the details with '-h' option for help menu"
  exit 1
fi


#################################################
#   Populate the Kubernetes related parameters
#################################################

echo "Populate the user related parameters"

# Populating the user details taken through command line
SECRET_PATH=`[ ${SECRET_PATH} ] && (echo ${SECRET_PATH}) || (echo "secret")`

############################
#  Vault Login
############################

echo "Logging on to the vault"
vault login -no-print -address=$VAULT_ADDR $VAULT_ROOT_TOKEN

############################################################
#  Create required vault access policy files for the user
############################################################

echo "Creating the policy file for the vault user"
echo "***vault policy write ${USERNAME}-policy ${POLICY_FILE_NAME}***"

cat <<EOF | vault policy write ${USERNAME}-policy -
path "secret/data/k8s/${USERNAME}/*" {
    capabilities = ["read", "list", "create", "delete", "update"]
}
path "secret/data/k8s" {
    capabilities = ["list"]
}
path "secret/data/${USERNAME}/*" {
    capabilities = ["read", "list", "create", "delete", "update"]
}
path "secret/data/common/*" {
    capabilities = ["read", "list"]
}
path "secret/metadata/*" {
    capabilities = ["list"]
}
EOF


################################################
#  Creating vault user attaching the policy
################################################

echo "*Creating vault user attaching the policy*"
echo "****vault write auth/ldap/users/${USERNAME} policies=${USERNAME}-policy"

vault write auth/ldap/users/${USERNAME} policies=${USERNAME}-policy



################################################
#  Login into vault with user credentials
################################################

echo "***The LDAP user should be able to login to the vault using the ldap credentials using the below command:"
echo "vault login -method=ldap username=${USERNAME}***"


echo ""
