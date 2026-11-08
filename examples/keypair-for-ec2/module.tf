module "key_pair" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/KeyPair?ref=main"

  key_name         = "${var.prefixo_projeto}-key"
  private_key_path = "keys/${var.prefixo_projeto}.pem"

  tags = {
    Environment = var.environment
    Project     = var.prefixo_projeto
    ManagedBy   = "Terraform"
  }
}
