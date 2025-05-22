data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  route_table_arns = [
    for id in var.route_table_ids :
    "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:route-table/${id}"
  ]
}



data "aws_iam_policy_document" "private-route-table-modifications" {
  statement {
      actions = ["ec2:DescribeRouteTables"]
      resources = ["*"]
  }

  statement {
      actions = [
          "ec2:CreateRoute",
          "ec2:DeleteRoute"
      ]
      resources = local.route_table_arns
  }
}

resource "aws_iam_role_policy" "trustgrid-route-policy" {
    name_prefix = "${var.name_prefix}-trustgrid-route-policy"
    policy = data.aws_iam_policy_document.private-route-table-modifications.json
    role = aws_iam_role.trustgrid-node.name
}

resource "aws_iam_role" "trustgrid-node" {
    name_prefix = "${var.name_prefix}-trustgrid-node"
    assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_instance_profile" "trustgrid-instance-profile" {
    name_prefix = "${var.name_prefix}-trustgrid-instance-profile"
    role = aws_iam_role.trustgrid-node.name
}