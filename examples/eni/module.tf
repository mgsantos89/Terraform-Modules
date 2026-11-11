
module "eni" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/ENI?ref=main"

  name        = "${var.prefixo_projeto}-eni"
  description = "Secondary network interface for EC2"

  subnet_id = var.subnet_id

  #private_ips = [
  #  "10.0.1.100",
  #  "10.0.1.101"
  #]

  security_group_ids = var.security_group_ids

  #instance_id = module.ec2.instance_id
  #device_index = 1

  source_dest_check = true

  tags = {
    Environment = var.environment
    Project     = var.prefixo_projeto
    ManagedBy   = "Terraform"
  }
}
