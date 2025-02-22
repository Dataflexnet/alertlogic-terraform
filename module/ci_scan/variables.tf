variable "account_id" {
  description = "AlertLogic Account ID."
}

variable "deployment_id" {
  description = "AlertLogic cloudinsight Deployment ID."
}

variable "stack" {
  description = "AlertLogic DataCenter where the appliance will be deployed in. Enter US or UK"
  default     = "US"
}

variable "vpc_id" {
  description = "Specify the VPC ID where the appliance will be deployed in."
}

variable "ci_subnet_id" {
  description = "Specify the existing subnet ID where the Scanning appliance will be deployed in."
}

variable "ci_subnet_type" {
  description = "Select if the subnet is a public or private subnet. Enter Public or Private"
}

variable "vpc_cidr" {
  description = "CIDR netblock for the VPC."
  type        = string
}

variable "ci_instance_type" {
  description = "AlertLogic Security Appliance EC2 instance type. Enter m3.medium, m3.large, m3.xlarge or m3.2xlarge"
  default     = "m3.medium"
}

variable "ci_appliance_number" {
  description = "Number of appliances to be deployed set by the Autoscaling group."
  default     = "1"
}

variable "stack_vaporator" {
  type = map(string)

  default = {
    "US.host" = "agentapi.cloudinsight.alertlogic.com"
    "US.port" = "443"
    "UK.host" = "agentapi.cloudinsight.alertlogic.co.uk"
    "UK.port" = "443"
  }
}

variable "internal" {
  description = "Internal tags for tracking deployment versions"
  default     = "3.0.0"
}
