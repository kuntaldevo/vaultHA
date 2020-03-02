




output "connections" {
  value = <<VAULT

  Vault Enterprise web interface  http://${aws_route53_record.ui.fqdn}
  Vault Enterprise ELB  http://${aws_elb.vault.dns_name}
VAULT
}
