mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      id = "us-east-1"
    }
  }
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"*\",\"Resource\":\"*\"}]}"
    }
  }
}

run "route_failover_only" {
  command = plan

  variables {
    enable_route_failover = true
    route_table_ids       = ["rtb-0123456789abcdef0"]
  }

  assert {
    condition     = length(aws_iam_role_policy.route_failover) == 1
    error_message = "Route failover policy must be created when enable_route_failover is true"
  }

  assert {
    condition     = length(aws_iam_role_policy.cluster_ip_failover) == 0
    error_message = "Cluster IP policy must not be created when enable_cluster_ip_failover is false"
  }
}

run "cluster_ip_failover_only" {
  command = plan

  variables {
    enable_cluster_ip_failover = true
  }

  assert {
    condition     = length(aws_iam_role_policy.cluster_ip_failover) == 1
    error_message = "Cluster IP policy must be created when enable_cluster_ip_failover is true"
  }

  assert {
    condition     = length(aws_iam_role_policy.route_failover) == 0
    error_message = "Route failover policy must not be created when enable_route_failover is false"
  }
}

run "both_failover_methods" {
  command = plan

  variables {
    enable_route_failover      = true
    route_table_ids            = ["rtb-0123456789abcdef0", "rtb-abcdef0123456789"]
    enable_cluster_ip_failover = true
  }

  assert {
    condition     = length(aws_iam_role_policy.route_failover) == 1
    error_message = "Route failover policy must be created when enable_route_failover is true"
  }

  assert {
    condition     = length(aws_iam_role_policy.cluster_ip_failover) == 1
    error_message = "Cluster IP policy must be created when enable_cluster_ip_failover is true"
  }
}

run "neither_failover_method_rejected" {
  command = plan

  expect_failures = [aws_iam_role.trustgrid_cluster]

  variables {
    enable_route_failover      = false
    enable_cluster_ip_failover = false
  }
}

run "route_failover_without_route_tables_rejected" {
  command = plan

  expect_failures = [aws_iam_role.trustgrid_cluster]

  variables {
    enable_route_failover = true
    route_table_ids       = []
  }
}
