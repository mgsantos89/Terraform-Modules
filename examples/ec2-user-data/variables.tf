variable "instance_name" {
  description = "Nome da Instancia"
  type        = string
}

variable "ami_id" {
  description = "ID da AMI (o script de exemplo foi feito para Amazon Linux 2023)"
  type        = string
}

variable "instance_type" {
  description = "Tipo de Instancia"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "ID da Subnet"
  type        = string
}

variable "security_group_ids" {
  description = "IDs dos Security Groups (libere a porta 80 para testar o nginx)"
  type        = list(string)
  default     = []
}

variable "prefixo_projeto" {
  description = "Prefixo do Projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente do Recurso"
  type        = string
  default     = "test"
}
