# Configure ldap(Paxata) users in the Vault cluster with specific user policy

This utility configures the ldap users with permission and access into few predefined paths to store and access secrets according to defined policy file.

This code does the following
 - Enabling Vault Authorization with LDAP engine
 - Login to the vault cluster with Root Vault Token having admin privileges
 - Enable Secret plugin to store secrets into a specific path
 - Create required vault access policy file for the user
 - Populate the user related parameters, i.e. SECRET_PATH
 - Applying user specific policy using policy file

# Prerequisites

To run the script the following are the pre-requisites
 - The controller machine should be in the same VPC to access the vault
 - The Vault must be up and running
 - The Vault URL & Root token should be available & to be updated in the vault-env.sh file

# Running the script

Before running the script the `vault-env.sh` file needs to be updated with the correct value of VAULT_ADDR and VAULT_TOKEN

The script accepts the following parameters

usage: ./ldap-vault-user.sh -s|h [value] -u [value] -p [value]

Options:
 - -h                  : print help message and exit
 - -s <secret path>    : logical path to which the secrets will be stored for the same user. default is "secret"
 - -u <username>       : username of the user for which the login is created

e.g  ./ldap-vault-user.sh -u <username>

# Output
 After every successful configuration of a ldap user, the script will provide the "output", which can be shared with the user for easy reference. Sample output can be found below:

 ```
 ***The LDAP user should be able to login to the vault using the ldap credentials using the below command:
 vault login -method=ldap username=sadey***
 The default access policy for the user set as:
 path "secret/k8s/sadey/*" {
     capabilities = ["read", "list", "create", "delete", "update"]
 }
 path "secret/k8s" {
     capabilities = ["list"]
 }
 path "secret/sadey/*" {
     capabilities = ["read", "list", "create", "delete", "update"]
 }
 path "secret/common/*" {
     capabilities = ["read", "list"]
 }
 path "secret/" {
     capabilities = ["list"]
 }
```
