module "eip" {
  source = "./EIP"

  name = "${var.prefixo_projeto}-eip"
  
  #instance_id = 

  tags = {
    Environment = var.environment
    Project     = var.prefixo_projeto
    ManagedBy   = "Terraform"
  }
}
