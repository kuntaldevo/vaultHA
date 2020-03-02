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
-p <password>       : ldap bind password. This is required just only once during configuring the LDAP with vault cluster. Once configured, its no more required for the consecutive ldap user configuration.
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
      p)
        PASSWORD="${OPTARG}"
        ;;
    esac
  done
  shift $((OPTIND-1))
done


############################
#  Vault Login
############################

echo "Logging on to the vault"
vault login -no-print -address=$VAULT_ADDR $VAULT_ROOT_TOKEN


##########################################################
#  Enabling Vault Authorization with LDAP engine
##########################################################

echo "***Enabling Vault Authorization for LDAP***"
echo "***vault auth enable ldap***"

LDAP=$(vault auth list | grep ldap  || true)
if [[ -n ${LDAP} ]];  then
  echo "ldap auth is already ENABLED"
else
  if [[ -z ${PASSWORD} ]]; then
    echo "ldap bindpass is a must to configure the ldap server with vault cluster."
    echo "Please get in touch with the LDAP admin for the required details & try again!!!!"
    exit 1
  else
    vault auth enable ldap

    #Once the ldap auth is enabled, it need to be configured with the LDAP server details
    vault write auth/ldap/config \
      url="ldaps://ldap.jumpcloud.com" \
      binddn="uid=ldap,ou=Users,o=5786b2d4e2022d5f0e1d9694,dc=jumpcloud,dc=com" \
      bindpass="${PASSWORD}" \
      userdn="ou=Users,o=5786b2d4e2022d5f0e1d9694,dc=jumpcloud,dc=com" \
      userattr="uid" \
      groupdn="ou=Users,o=5786b2d4e2022d5f0e1d9694,dc=jumpcloud,dc=com" \
      groupattr="cn" \
      insecure_tls=false
  fi
fi
