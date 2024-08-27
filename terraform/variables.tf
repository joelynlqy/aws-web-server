# VPC
variable vpc_name {
  type        = string
  default     = "vpc_1"
  description = "VPC Name"
}

variable vpc_cidr {
  type = string 
  default = "10.0.0.0/16"
  description = "VPC CIDR Block"
}

variable vpc_azs {
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
  description = "VPC Availability Zones"
}

variable vpc_private_subnets {
  type        = list(string)
  default     = ["10.0.0.0/18", "10.0.64.0/24"]
  description = "description"
}

variable vpc_public_subnets {
  type        = list(string)
  default     = ["10.0.128.0/24", "10.0.192.0/24"]
  description = "description"
}

# SG
variable sg_name {
  type        = string
  default     = "sg_1"
  description = "Security Group Name"
}

variable sg_ingress_rules {
  type        = list(string)
  default     = ["ssh-tcp", "http-80-tcp"]
  description = "Security Ingress Rules"
}

variable sg_ingress_cidr {
  type        = string
  default     = "x.x.x.x/32"
  description = "Security Ingress CIDR Block"
}

# Key-Pair
variable key_name {
  type        = string
  default     = "key_1"
  description = "Key-Pair Name"
}


# EC2
variable ec2_ami {
  type        = string
  default     = "ami-0d07675d294f17973"
  description = "EC2 AMI"
}
variable ec2_instance_name {
  type        = string
  default     = "ec2_1"
  description = "EC2 Instance Name"
}

variable instance_type {
  type        = string
  default     = "t2.micro"
  description = "EC2 Instance Type"
}
