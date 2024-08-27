# VPC
output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "vpc_nat_public_ips" {
  value       = module.vpc.nat_public_ips
  description = "NAT Gateway Public Elastic IPs"
}

# SG
output "sg_group_id" {
  value       = module.security_group.security_group_id
  description = "The ID of the security group"
}

# Key-Pair
output "public_key_pem" {
  value       = module.key_pair.public_key_pem
  description = "Public Key PEM"
}


# EC2
output "instance_pid" {
  value = module.ec2_instance.id
  description = "EC2 Instance ID"
}

output "instance_public_ip" {
  value = module.ec2_instance.public_ip
  description = "EC2 Instance Public IP"
}