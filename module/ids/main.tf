// Data sources
data "aws_region" "current" {
}

data "http" "image_data" {
  url = "https://s3.amazonaws.com/cd.prod.manual-mode.repository/images/latest/ids_images.json"

  request_headers = {
    Accept = "application/json"
  }
}

locals {
  aws_region = data.aws_region.current.region

  alert_logic_data    = jsondecode(data.http.image_data.response_body)
  alert_logic_regions = local.alert_logic_data["RegionSettings"]
  alert_logic_region  = lookup(local.alert_logic_regions, local.aws_region, "Region not found")

  image_id = local.alert_logic_region.ImageId
}

// create launch configuration for the IDS security appliances to be created
resource "aws_launch_template" "ids_appliance_lt" {
  count = var.create_ids

  name_prefix   = "al-ids-lt"
  image_id      = local.image_id
  instance_type = var.ids_instance_type

  vpc_security_group_ids = [aws_security_group.ids_appliance_sg[0].id]

  lifecycle {
    create_before_destroy = true
  }
}

// create ASG to have the specified amount of IDS security appliances up and running using the created launch configuration
resource "aws_autoscaling_group" "ids_appliance_asg" {
  count = var.create_ids

  name                = "al-ids-asg"
  max_size            = var.ids_appliance_number
  min_size            = var.ids_appliance_number
  desired_capacity    = var.ids_appliance_number
  force_delete        = true
  vpc_zone_identifier = var.ids_subnet_id

  launch_template {
    id      = aws_launch_template.ids_appliance_lt[0].id
    version = "$Default"
  }

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "AlertLogic IDS Security Appliance"
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
    key                 = "Alertlogic IDS Manual Mode Template Version"
    value               = var.internal
    propagate_at_launch = "true"
  }
}

// create security group to allow IDS security appliance traffic to flow outbound to Alert Logic DataCenter (resitricted and required outbound rules will be applied)
resource "aws_security_group" "ids_appliance_sg" {
  name        = "al-ids-sg"
  count       = var.create_ids
  description = "AlertLogic IDS Security Group"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    from_port   = 7777
    to_port     = 7777
  }

  ingress {
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    from_port   = 443
    to_port     = 443
  }

  egress {
    protocol    = "tcp"
    cidr_blocks = ["204.110.218.96/27"]
    from_port   = 443
    to_port     = 443
  }

  egress {
    protocol    = "tcp"
    cidr_blocks = ["204.110.219.96/27"]
    from_port   = 443
    to_port     = 443
  }

  egress {
    protocol    = "tcp"
    cidr_blocks = ["208.71.209.32/27"]
    from_port   = 443
    to_port     = 443
  }

  egress {
    protocol    = "tcp"
    cidr_blocks = ["185.54.124.0/24"]
    from_port   = 443
    to_port     = 443
  }

  egress {
    protocol    = "tcp"
    cidr_blocks = ["204.110.218.96/27"]
    from_port   = 4138
    to_port     = 4138
  }

  egress {
    protocol    = "tcp"
    cidr_blocks = ["204.110.219.96/27"]
    from_port   = 4138
    to_port     = 4138
  }

  egress {
    protocol    = "tcp"
    cidr_blocks = ["208.71.209.32/27"]
    from_port   = 4138
    to_port     = 4138
  }

  egress {
    protocol    = "tcp"
    cidr_blocks = ["185.54.124.0/24"]
    from_port   = 4138
    to_port     = 4138
  }

  egress {
    protocol    = "udp"
    cidr_blocks = ["8.8.8.8/32"]
    from_port   = 53
    to_port     = 53
  }

  egress {
    protocol    = "udp"
    cidr_blocks = ["8.8.4.4/32"]
    from_port   = 53
    to_port     = 53
  }

  egress {
    protocol    = "tcp"
    cidr_blocks = ["8.8.8.8/32"]
    from_port   = 53
    to_port     = 53
  }

  egress {
    protocol    = "tcp"
    cidr_blocks = ["8.8.4.4/32"]
    from_port   = 53
    to_port     = 53
  }

  tags = {
    "Name"                                        = "AlertLogic IDS Security Group"
    "AlertLogic-AccountID"                        = var.account_id
    "AlertLogic-EnvironmentID"                    = var.deployment_id
    "AlertLogic"                                  = "Security"
    "Alertlogic IDS Manual Mode Template Version" = var.internal
    "Purpose"                                     = "al-ids"
  }
}
