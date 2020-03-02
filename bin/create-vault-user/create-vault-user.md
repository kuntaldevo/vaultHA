# Create an User in the Vault cluster with specific user policy


This code creates an user with permission and access in specific paths to store and access secrets according to defined user-policy file.
This code does the following
 - Populate the user related parameters,i.e. SECRET_PATH and PASSWORD
 - Login to the vault cluster with Root Vault Token having admin privileges
 - Enable Secret plugin to store secrets into a specific path
 - Enabling Vault Authorization with USERPASS engine
 - Create required vault access policy file for the user
 - Applying user specific policy using policy file
 - Creating vault user with the specific user-policy attached


# Prerequisites
To run the script the following are the pre-requisites
 - The controller machine should be in the same VPC to access the vault
 - The Vault must be up and running


# Running the script
 Before running the script the          vault-env.sh file needs to be updated with the correct value of VAULT_ADDR and VAULT_TOKEN

 The script accepts the following parameters

 -s <secret path>    : logical path to which the secrets will be stored for the same user. default is "secret"
 -u <username>       : username of the user for which the login is created (MANDATORY)
 -p <password>       : password for the user. default is "password"

 e.g  ./create-vault-user.sh -u <username>
