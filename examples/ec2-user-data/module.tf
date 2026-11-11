module "ec2" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/EC2?ref=main"

  name          = var.instance_name
  ami_id        = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  associate_public_ip_address = true
  security_group_ids          = var.security_group_ids

  root_volume_size = 10

  # Script renderizado a partir do template. Não coloque segredos aqui:
  # o conteúdo fica salvo no state e visível na metadata da instância.
  user_data = templatefile("${path.module}/scripts/user-data.sh.tftpl", {
    instance_name = var.instance_name
    environment   = var.environment
  })

  # Recria a instância quando o script mudar, garantindo que ele rode de novo.
  user_data_replace_on_change = true

  # IMDSv2 obrigatório (padrão do módulo, declarado aqui para ficar explícito).
  metadata_http_tokens= "required"
  metadata_http_put_response_hop_limit = 1

  tags = {
    Environment = var.environment
    Project     = var.prefixo_projeto
    ManagedBy   = "Terraform"
  }
}
