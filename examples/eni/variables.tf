variable "subnet_id" {
  description = "ID da Subnet"
  type        = string
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

variable "security_group_ids" {
  description = "IDs dos Security Groups da ENI. Vazio usa o Security Group default da VPC"
  type        = list(string)
  default     = []
}
