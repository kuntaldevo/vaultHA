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
EOF
  echo $1
  exit 1
}

#POSITIONAL_ARGS=""
while [ $# -gt 0 ]; do
  while getopts ":s:p:h" arg; do
    case "${arg}" in
      h)
        bail
        ;;
      s)
        SECRET_PATH="${OPTARG}"
        ;;
    esac
  done
  shift $((OPTIND-1))
done


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

#################################################################
#  Enable Secret plugin to store secrets into a specific path
#################################################################

HAS_SECRET=$(vault secrets list | awk {'print $1'} | grep secret  || true )

if [[ -n $HAS_SECRET ]];then
  echo "secret engine is already enabled!!!!"
else
  echo "***Enable the secret database for the secret engine***"
  echo "***vault secrets enable -path=${SECRET_PATH} kv***"

  vault secrets enable -path=${SECRET_PATH} kv
  vault kv enable-versioning secret/
fi
