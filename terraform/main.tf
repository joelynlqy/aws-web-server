# VPC -> https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.vpc_azs
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  enable_nat_gateway = true
  enable_vpn_gateway = true
}

# Security Group -> https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest
# Named Rules -> https://github.com/terraform-aws-modules/terraform-aws-security-group/blob/master/rules.tf
module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.2"

  name        = var.sg_name
  description = "Allow ingress for SSH-TCP and HTTP-80-TCP, egress for all"
  vpc_id      = module.vpc.vpc_id

  ingress_rules       = var.sg_ingress_rules
  ingress_cidr_blocks = [module.vpc.vpc_cidr_block, var.sg_ingress_cidr, "3.0.5.32/29"]
  egress_rules        = ["all-all"]
}

# Key-Pair -> https://registry.terraform.io/modules/terraform-aws-modules/key-pair/aws/latest
module "key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "2.0.3"

  key_name           = var.key_name
  create_private_key = true
}

resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_key" {
  filename = "${var.key_name}.pem"
  content = tls_private_key.pk.private_key_pem
}

# VM -> https://registry.terraform.io/modules/terraform-aws-modules/ec2-instance/aws/latest
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.6.1"

  name = var.ec2_instance_name
  ami  = var.ec2_ami

  instance_type          = var.instance_type
  key_name               = module.key_pair.key_pair_name
  monitoring             = true

  associate_public_ip_address = true

  vpc_security_group_ids = [module.security_group.security_group_id]

  subnet_id =  module.vpc.public_subnets[0]
}