

data "template_file" "vault" {

  template = "${file("userdata.tpl")}"

  vars = {
    kms_key    = "${var.vault-key}"
    api-addr = "vault.paxata.ninja"
    vault_url  = "${var.vault-url}"
    region-id = "${var.region-id}"
    cluster_size = "${var.vault-cluster-size}"
    environment_name = "${var.environment-name}"
  }
}
