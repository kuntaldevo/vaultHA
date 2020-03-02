
data "aws_route53_zone" "private" {

  name = "${var.paxata-domain}"

  private_zone = true

}

### Expose the UI
resource "aws_route53_record" "ui" {

  zone_id = "${data.aws_route53_zone.private.zone_id}"
  name    = "vault"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_elb.vault.dns_name}"]
}
