// Data sources
data "aws_region" "current" {
}

data "http" "image_data" {
  url = "https://s3.amazonaws.com/cd.prod.manual-mode.repository/images/latest/scan_images.json"

  request_headers = {
    Accept = "application/json"
  }
}

locals {
  aws_region = data.aws_region.current.name

  alert_logic_data    = jsondecode(data.http.image_data.response_body)
  alert_logic_regions = local.alert_logic_data["RegionSettings"]
  alert_logic_region  = lookup(local.alert_logic_regions, local.aws_region, "Region not found")

  image_id = local.alert_logic_region.ImageId
}

// create launch template for the security appliances to be created
resource "aws_launch_template" "ci_appliance_lt" {
  name_prefix   = "al-scan-lt"
  image_id      = local.image_id
  instance_type = var.ci_instance_type

  vpc_security_group_ids = [aws_security_group.ci_appliance_sg.id]

  user_data = base64encode(templatefile("${path.module}/userdata.tpl",
    {
      stack_host    = var.stack_vaporator["${var.stack}.host"]
      stack_port    = var.stack_vaporator["${var.stack}.port"]
      account_id    = var.account_id
      deployment_id = var.deployment_id
    }
  ))

  lifecycle {
    create_before_destroy = true
  }
}

// create ASG to have the specified amount of security appliances up and running using the created launch configuration
resource "aws_autoscaling_group" "ci_appliance_asg" {
  name                = "al-scan-asg"
  max_size            = var.ci_appliance_number
  min_size            = var.ci_appliance_number
  desired_capacity    = var.ci_appliance_number
  force_delete        = true
  vpc_zone_identifier = [var.ci_subnet_id]

  launch_template {
    id      = aws_launch_template.ci_appliance_lt.id
    version = "$Default"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity, min_size, max_size]
  }

  tag {
    key                 = "Name"
    value               = "AlertLogic Security Appliance"
    propagate_at_launch = "true"
  }

  tag {
    key                 = "AlertLogic-AccountID"
    value               = var.account_id
    propagate_at_launch = "true"
  }

  tag {
    key                 = "AlertLogic-EnvironmentID"
    value               = var.deployment_id
    propagate_at_launch = "true"
  }

  tag {
    key                 = "AlertLogic"
    value               = "Security"
    propagate_at_launch = "true"
  }

  tag {
    key                 = "Alertlogic CI Scan Appliance Manual Mode Template Version"
    value               = var.internal
    propagate_at_launch = "true"
  }
}

// create security group to allow security appliance traffic to flow outbound to any destination IP on specific ports. In general, it will have no rules, which basically allows all traffic outbound but is resitricted to specific ports required for communication
resource "aws_security_group" "ci_appliance_sg" {
  name        = "al-scan-sg"
  description = "AlertLogic Security Group"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    "Name"                                                      = "AlertLogic Security Group"
    "AlertLogic-AccountID"                                      = var.account_id
    "AlertLogic-EnvironmentID"                                  = var.deployment_id
    "AlertLogic"                                                = "Security"
    "Alertlogic CI Scan Appliance Manual Mode Template Version" = var.internal
    "Purpose"                                                   = "al-scan"
  }
}
