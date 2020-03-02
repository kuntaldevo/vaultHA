data "aws_iam_policy_document" "dynamodb" {

  statement {
    sid       = "VaulDynamoDB"
    effect    = "Allow"
    resources = ["arn:aws:dynamodb:${var.region-id}:${var.account-id}:table/vault-data"]

    actions = [
    "dynamodb:DescribeLimits",
    "dynamodb:DescribeTimeToLive",
    "dynamodb:ListTagsOfResource",
    "dynamodb:DescribeReservedCapacityOfferings",
    "dynamodb:DescribeReservedCapacity",
    "dynamodb:ListTables",
    "dynamodb:BatchGetItem",
    "dynamodb:BatchWriteItem",
    "dynamodb:CreateTable",
    "dynamodb:DeleteItem",
    "dynamodb:GetItem",
    "dynamodb:GetRecords",
    "dynamodb:PutItem",
    "dynamodb:Query",
    "dynamodb:UpdateItem",
    "dynamodb:Scan",
    "dynamodb:DescribeTable"
    ]
  }
}
