terraform {
  required_version = ">= 1.2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  route_table_arns = [
    for id in var.route_table_ids :
    "arn:aws:ec2:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:route-table/${id}"
  ]
}

data "aws_iam_policy_document" "route_failover" {
  count = var.enable_route_failover ? 1 : 0

  statement {
    actions   = ["ec2:DescribeRouteTables"]
    resources = ["*"]
  }

  statement {
    actions = [
      "ec2:CreateRoute",
      "ec2:DeleteRoute",
    ]
    resources = local.route_table_arns
  }
}

data "aws_iam_policy_document" "cluster_ip_failover" {
  count = var.enable_cluster_ip_failover ? 1 : 0

  statement {
    sid = "DescribeForFailover"
    actions = [
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeInstances",
    ]
    resources = ["*"]
  }

  statement {
    sid = "ManageSecondaryIPs"
    actions = [
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "trustgrid_cluster" {
  name_prefix = "${var.name_prefix}-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Sid       = ""
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  lifecycle {
    precondition {
      condition     = var.enable_route_failover || var.enable_cluster_ip_failover
      error_message = "At least one of enable_route_failover or enable_cluster_ip_failover must be true."
    }
    precondition {
      condition     = !var.enable_route_failover || length(var.route_table_ids) > 0
      error_message = "route_table_ids must be provided when enable_route_failover is true."
    }
  }
}

resource "aws_iam_role_policy" "route_failover" {
  count       = var.enable_route_failover ? 1 : 0
  name_prefix = "${var.name_prefix}-route-failover-"
  role        = aws_iam_role.trustgrid_cluster.name
  policy      = data.aws_iam_policy_document.route_failover[0].json
}

resource "aws_iam_role_policy" "cluster_ip_failover" {
  count       = var.enable_cluster_ip_failover ? 1 : 0
  name_prefix = "${var.name_prefix}-cluster-ip-failover-"
  role        = aws_iam_role.trustgrid_cluster.name
  policy      = data.aws_iam_policy_document.cluster_ip_failover[0].json
}

resource "aws_iam_instance_profile" "trustgrid_cluster" {
  name_prefix = "${var.name_prefix}-"
  role        = aws_iam_role.trustgrid_cluster.name
}
