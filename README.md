# Vault Autounseal using AWS KMS

In this guide, we'll show an example of how to use Terraform to provision a cluster that can utilize an encryption key from AWS Key Management Services to unseal Vault.

## Overview
Vault unseal operation either requires either a number of people who each possess a shard of a key, split by Shamir's Secret sharing algorithm, or protection of the master key via an HSM or cloud key management services (Google CKMS or AWS KMS). 

This guide has a guide on how to implement and use this feature in AWS. Included is a Terraform configuration that has the following features:  
* Ubuntu 16.04 LTS with Vault Enterprise (0.9.0+prem.hsm).   
* An instance profile granting the AWS EC2 instance to a KMS key.   
* Vault configured with access to a KMS key.   


## Prerequisites

This guide assumes the following:   

1. Access to Vault Enterprise > 0.9.0 which supports AWS KMS as an unseal mechanism. 
1. A URL to download Vault Enterprise from (an S3 bucket will suffice). 
1. Saml2aws configured for AWS access.
1. Terraform installed, and basic understanding of its usage


## Usage
Instructions assume this location as a working directory, as well as AWS credentials exposed as environment variables

1. Set Vault Enterprise URL and other parameters in a file named variables.tf (eg. aws_region, vault_url, vpc_id, subnets, deployment_type, instance_type, vault-cluster-size, node-volume-size)
1. Perform the following to provision the environment

```
terraform init
terraform plan
terraform apply
```

Outputs will contain instructions to connect to the server via SSH

```
Apply complete! Resources: 12 added, 0 changed, 0 destroyed.

Outputs:

connections =
Vault Enterprise web interface  http://internal-Paxata-Dev-vault-ELB-XXXXXXX.XXXXXXXXXXX.elb.amazonaws.com

Connect to Node1 via SSH::   ssh ubuntu@10.XX.XX.XX -i private.key
Connect to Node2 via SSH::   ssh ubuntu@10.XX.XX.XX -i private.key
Connect to Node3 via SSH::   ssh ubuntu@10.XX.XX.XX -i private.key

```

Login to one of the instances

```
# vault status
Error checking seal status: Error making API request.

URL: GET http://127.0.0.1:8200/v1/sys/seal-status
Code: 400. Errors:

* server is not yet initialized

# Active a primary node
# vault operator init -stored-shares=1 -recovery-shares=1 -recovery-threshold=1 -key-shares=1 -key-threshold=1
-stored-shares has no effect and will be removed in Vault 1.3.

Recovery Key 1: IPm7Qh6Htgy+mJ4oPQXXXXXXXXXXXXXXXXXXXXXXXXXD0ey0=

Initial Root Token: s.TB4LgRXXXXXXXXXXXXXXXXXXIIp

Success! Vault is initialized

Recovery key initialized with 1 key shares and a key threshold of 1. Please
securely distribute the key shares printed above.

WARNING! -key-shares and -key-threshold is ignored when Auto Unseal is used.
Use -recovery-shares and -recovery-threshold instead.

# systemctl stop vault

# vault status
Error checking seal status: Get http://127.0.0.1:8200/v1/sys/seal-status: dial tcp 127.0.0.1:8200: getsockopt: connection refused

# systemctl start vault

# vault status
Key                      Value
---                      -----
Recovery Seal Type       shamir
Initialized              true
Sealed                   false
Total Recovery Shares    1
Threshold                1
Version                  1.1.3
Cluster Name             vault-cluster-e44d27fc
Cluster ID               c6b68071-9155-3fdd-13db-c7f4d213ca69
HA Enabled               true
HA Cluster               https://10.241.185.30:8201
HA Mode                  standby
Active Node Address      http://10.241.185.30:8200

As mentioned in the above output that its not the Active Node, rather a stanby one. check "HA Mode".

# vault auth <Initial Root Token>
Successfully authenticated! You are now logged in.
token: s.TB4LgRXXXXXXXXXXXXXXXXXXIIp
token_duration: 0
token_policies: [root]

# cat /etc/vault.d/vault.hcl
storage "consul" {
 address = "127.0.0.1:8500"
}
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}
seal "awskms" {
  kms_key_id = "d7c1ffd9-8cce-45e7-be4a-bb38dd205966"
}
ui=true
```

Login to a different node and check the status of Vault (One of them should now be active)

```
export VAULT_ADDR='http://internal-Paxata-Dev-vault-ELB-XXXXXXX.XXXXXXXXXXX.elb.amazonaws.com'

$ vault status
Key                      Value
---                      -----
Recovery Seal Type       shamir
Initialized              true
Sealed                   false
Total Recovery Shares    1
Threshold                1
Version                  1.1.3
Cluster Name             vault-cluster-e44d27fc
Cluster ID               c6b68071-9155-3fdd-13db-c7f4d213ca69
HA Enabled               true
HA Cluster               https://10.241.185.30:8201
HA Mode                  active

$ vault login <Initial Root Token>  ## This can also be the client token
```

Once complete perform the following to clean up

```
export TF_WARN_OUTPUT_ERRORS=1  ## This is a hack to remove warnings/errors while output is evaluated for resources that terrafrom doesn't create while destroying.

terraform destroy -force
rm -rf .terraform terraform.tfstate* private.key

```

## Troubleshooting

### Error while destroy:

There are couple of resources not directly created by the TF, however those are being used for producing the `output` message. So while doing a delete `terraform destroy` it may produce some error as mentioned below.

```
Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes


Error: Error applying plan:

1 error(s) occurred:

* output.connections: Resource 'data.aws_instance.vault-node.0' does not have attribute 'private_ip' for variable 'data.aws_instance.vault-node.0.private_ip'
```

However this can be managed by enabling a TF parameter `TF_WARN_OUTPUT_ERRORS` to `1`.

```
export TF_WARN_OUTPUT_ERRORS=1
```
& finally it deletes all the resources got created previously.

```
aws_security_group.elb: Destruction complete after 1m28s

Destroy complete! Resources: 12 destroyed.
```
