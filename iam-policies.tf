data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "vault-policy-doc" {
  statement {
    sid       = "VaultKMSUnseal"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
      "ec2:DescribeInstances"
    ]
  }
}

resource "aws_iam_role" "vault-role" {
  name               = "vault-role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_iam_role_policy" "vault-policy" {
  name   = "vault-policy"
  role   = "${aws_iam_role.vault-role.id}"
  policy = "${data.aws_iam_policy_document.vault-policy-doc.json}"
}

resource "aws_iam_instance_profile" "vault-instance-profile" {
  name = "vault-instance-profile"
  role = "${aws_iam_role.vault-role.name}"
}

resource "aws_iam_policy" "dynamodb" {
  name   = "vault-dynamodb"
  policy = "${data.aws_iam_policy_document.dynamodb.json}"

}
resource "aws_iam_policy" "ha" {
  name   = "vault-ha"
  policy = "${data.aws_iam_policy_document.ha.json}"

}

resource "aws_iam_role_policy_attachment" "dynamodb" {

    role       = "${aws_iam_role.vault-role.name}"

    policy_arn = "${aws_iam_policy.dynamodb.arn}"

}
resource "aws_iam_role_policy_attachment" "ha" {

    role       = "${aws_iam_role.vault-role.name}"

    policy_arn = "${aws_iam_policy.ha.arn}"

}
