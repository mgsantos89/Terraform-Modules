
module "security_group" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/SecurityGroup?ref=main"

  name        = "${var.prefixo_projeto}-sg"
  description = "Security Group for EC2"
  vpc_id      = var.vpc_id

  ingress_rules = {
    ssh = {
      description = "SSH access"
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }

    http = {
      description = "HTTP access"
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

    egress_rules = {
      all_ipv4 = {
        description = "Allow all outbound IPv4"
        ip_protocol = "-1"
        cidr_ipv4   = "0.0.0.0/0"
      }

  }

  tags = {
    Environment = var.environment
    Project     = var.prefixo_projeto
    ManagedBy   = "Terraform"
  }
}
