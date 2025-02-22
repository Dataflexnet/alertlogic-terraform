variable "account_id" {
  description = "AlertLogic Account ID."
}

variable "deployment_id" {
  description = "AlertLogic cloudinsight Deployment ID."
}

variable "vpc_id" {
  description = "Specify the VPC ID where the appliance will be deployed in."
}

variable "ids_subnet_id" {
  description = "Specify the existing subnet ID(s) where the appliance will be deployed in."
  type        = list(string)
}

variable "ids_subnet_type" {
  description = "Select if the subnet is a public or private subnet. Enter Public or Private"
}

variable "vpc_cidr" {
  description = "CIDR netblock of the VPC to be monitored (Where agents will be installed)."
  type        = string
}

variable "ids_instance_type" {
  description = "AlertLogic Security Appliance EC2 instance type. Enter m3.medium, m3.large, m3.xlarge or m3.2xlarge"
  default     = "m3.medium"
}

variable "ids_appliance_number" {
  description = "Number of appliances to be deployed set by the Autoscaling group."
}

variable "create_ids" {
  description = "Set value to 1(true) to include IDS coverage for the Professional protection subscription tier, otherwise set to 0(false) if your scope of protection set to Essentials/Scanning only, IDS will not be deployed."
}

variable "internal" {
  description = "Internal tags for tracking deployment versions"
  default     = "3.0.0"
}
