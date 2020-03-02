


resource "aws_security_group" "vault" {

  name        = "vault-node-sg"
  description = "vault access"
  vpc_id      = "${var.vpc-id}"

  tags = var.tag-map

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
    description = "Paxata Subnets"
  }


  # AllowAllOutbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "AllowAllOutBound"
  }
}

## Security Group for ELB
resource "aws_security_group" "elb" {

  name = "vault"
  vpc_id      = "${var.vpc-id}"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "AllowAllOutBound"
  }
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["10.0.0.0/8"]
    description = "Paxata Subnets"
  }
  tags = var.tag-map
}
