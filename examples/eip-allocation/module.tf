module "eip" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/EIP?ref=main"

  name = "${var.prefixo_projeto}-eip"
  
  #instance_id = 

  tags = {
    Environment = var.environment
    Project     = var.prefixo_projeto
    ManagedBy   = "Terraform"
  }
}