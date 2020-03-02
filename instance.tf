

resource "aws_instance" "vault" {

  count = "${var.vault-cluster-size}"

  ami      = "${data.aws_ami.aws.id}"
  instance_type = "${var.instance-type}"
  iam_instance_profile  = "${aws_iam_instance_profile.vault-instance-profile.id}"
  key_name              = "${var.aws-key-pair}"
  vpc_security_group_ids      = ["${aws_security_group.vault.id}"]
  subnet_id     = "${element(var.subnets, count.index)}"


#Required by AWS Linux
  root_block_device {
    volume_size = "30"
  }

  lifecycle {
    create_before_destroy = true
  }

  user_data = "${data.template_file.vault.rendered}"

  tags = "${merge(var.tag-map, map("Name", "vault-${count.index}","tf-resource", "aws_instance.vault"))}"

}
