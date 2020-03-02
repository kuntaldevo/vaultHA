variable region-id {
  description = "AWS region"
}

variable vault-url {
  default = "https://releases.hashicorp.com/vault/1.2.3/vault_1.2.3_linux_amd64.zip"
}

variable environment-name {
  default = "paxata-vault"
}

variable vault-key {

  description = "This is the initial key used to unlock the vault.  Should only be stored in lastpass and build machines"
}


variable vpc-id {
  description = "The default VPC (dev-private-vpc) where the EKS clusters are launched."
}

variable subnets {
  description = "The private subnets of the default VPC (dev-private-vpc) where the EKS clusters are launched."
}

variable instance-type {
  default = "t3.medium"
  description = "default is t2.micro & can be changed"
}

variable vault-cluster-size {
  default = "3"
  description = "The default cluster size is 3 node"
}

variable tag-map {
  type =  map
}

variable paxata-domain {
  description = "The TLD to use"
}

variable aws-key-pair {}

variable env-key {
  description = "Not used. Placate TF 12"
}
variable account-id {
  description = "Not used. Placate TF 12"
}
variable profile-id {
  description = "Not used. Placate TF 12"
}
