
resource "aws_elb" "vault" {

  name = "vault"

  internal = "true"

  instances = aws_instance.vault.*.id
  security_groups = ["${aws_security_group.elb.id}"]
  subnets = "${var.subnets}"

  health_check {
    healthy_threshold = 10
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:8200/v1/sys/health"
  }

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "8200"
    instance_protocol = "http"
  }

  tags = var.tag-map
}
