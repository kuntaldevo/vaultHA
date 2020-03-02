
Make Sure that LDAP for Vault is configured.

# Configure ldap(Paxata) users in the Vault cluster with specific user policy

This utility configures the ldap users with permission and access into few predefined paths to store and access secrets according to defined policy file.

This code does the following
 - Enabling Vault Authorization with LDAP engine
 - Login to the vault cluster with Root Vault Token having admin privileges
 - Enable Secret plugin to store secrets into a specific path

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
 - -p <password>       : ldap bind password. This is required just only once during configuring the LDAP with vault cluster. Once configured, it's no more required for the consecutive ldap user configuration.

e.g  ./configure-ldap.sh -p <<bind-password>>
