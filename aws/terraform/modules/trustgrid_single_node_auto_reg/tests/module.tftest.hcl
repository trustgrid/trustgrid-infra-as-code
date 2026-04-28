mock_provider "aws" {
  mock_data "aws_ami" {
    defaults = {
      id = "ami-0123456789abcdef0"
    }
  }
  mock_data "aws_iam_instance_profile" {
    defaults = {
      name = "test-profile"
      arn  = "arn:aws:iam::123456789012:instance-profile/test-profile"
    }
  }
  mock_data "aws_region" {
    defaults = {
      name = "us-east-1"
    }
  }
  mock_data "aws_subnet" {
    defaults = {
      vpc_id = "vpc-0123456789abcdef0"
    }
  }
}

mock_provider "cloudinit" {}

variables {
  name                          = "test-node"
  management_subnet_id          = "subnet-mgmt0123456789"
  management_security_group_ids = ["sg-0123456789abcdef0"]
  data_subnet_id                = "subnet-data0123456789"
  data_security_group_ids       = ["sg-abcdef0123456789"]
  key_pair_name                 = "test-keypair"
  license                       = "test-license-key"
}

run "network_security_defaults" {
  command = plan

  assert {
    condition     = aws_eip.mgmt_ip.domain == "vpc"
    error_message = "EIP must be allocated in VPC domain"
  }

  assert {
    condition     = aws_network_interface.management_eni.source_dest_check == false
    error_message = "Management ENI must have source_dest_check disabled for Trustgrid routing"
  }

  assert {
    condition     = aws_network_interface.data_eni.source_dest_check == false
    error_message = "Data ENI must have source_dest_check disabled for Trustgrid routing"
  }
}

run "imdsv2_enforced" {
  command = plan

  assert {
    condition     = aws_instance.node.metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 must be enforced (http_tokens = required)"
  }

  assert {
    condition     = aws_instance.node.metadata_options[0].http_endpoint == "enabled"
    error_message = "Instance metadata endpoint must be enabled"
  }
}

run "root_volume_encrypted_by_default" {
  command = plan

  assert {
    condition     = aws_instance.node.root_block_device[0].encrypted == true
    error_message = "Root block device must be encrypted by default"
  }

  assert {
    condition     = aws_instance.node.root_block_device[0].volume_type == "gp3"
    error_message = "Root block device must use gp3 volume type"
  }
}

run "no_gateway_rules_by_default" {
  command = plan

  assert {
    condition     = length(aws_security_group_rule.tcp_tggw) == 0
    error_message = "TCP gateway rule must not be created when is_tggateway is false"
  }

  assert {
    condition     = length(aws_security_group_rule.udp_tggw) == 0
    error_message = "UDP gateway rule must not be created when is_tggateway is false"
  }
}

run "tggateway_opens_correct_ports" {
  command = plan

  variables {
    is_tggateway = true
  }

  assert {
    condition     = length(aws_security_group_rule.tcp_tggw) == 1
    error_message = "TCP gateway rule must be created when is_tggateway is true"
  }

  assert {
    condition     = length(aws_security_group_rule.udp_tggw) == 1
    error_message = "UDP gateway rule must be created when is_tggateway is true"
  }

  assert {
    condition     = aws_security_group_rule.tcp_tggw[0].from_port == 8443
    error_message = "TCP gateway rule must use default port 8443"
  }

  assert {
    condition     = aws_security_group_rule.udp_tggw[0].from_port == 8443
    error_message = "UDP gateway rule must use default port 8443"
  }
}

run "instance_type_validation_rejects_invalid" {
  command = plan

  expect_failures = [var.instance_type]

  variables {
    instance_type = "m5.large"
  }
}

run "in_place_attributes_are_tracked" {
  command = plan

  assert {
    condition     = aws_instance.node.instance_type == var.instance_type
    error_message = "instance_type must be tracked so in-place resize is possible via Terraform"
  }

  assert {
    condition     = aws_instance.node.tags["Name"] == var.name
    error_message = "Name tag must be tracked so tag corrections can be applied in-place"
  }
}
