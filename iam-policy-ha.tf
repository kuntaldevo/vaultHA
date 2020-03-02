data "aws_iam_policy_document" "ha" {

  statement {
    sid       = "HA"
    effect    = "Allow"
    resources = ["*"]

    actions = [
    "ssm:ListInventoryEntries",
    "ssm:DescribePatchGroups",
    "ssm:ListComplianceItems",
    "ssm:ListDocumentVersions",
    "ssm:DescribeSessions",
    "ssm:DescribeMaintenanceWindowSchedule",
    "ssm:ListAssociationVersions",
    "ssm:DescribePatchBaselines",
    "ec2messages:GetMessages",
    "ssm:ListInstanceAssociations",
    "ssm:ListResourceComplianceSummaries",
    "ssm:DescribeMaintenanceWindowExecutionTaskInvocations",
    "ssm:DescribeMaintenanceWindowExecutionTasks",
    "ssm:ListComplianceSummaries",
    "ssm:UpdateInstanceInformation",
    "ssm:DescribeParameters",
    "ssm:DescribeMaintenanceWindows",
    "ssm:ListResourceDataSync",
    "ssm:ListDocuments",
    "ssm:DescribeMaintenanceWindowsForTarget",
    "ssm:ListAssociations"
    ]
  }
}
