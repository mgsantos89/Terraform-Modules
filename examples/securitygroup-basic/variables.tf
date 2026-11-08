variable "vpc_id" {
    description = "ID da VPC"
    type = string
}

variable "prefixo_projeto" {
    description = "Prefixo do Projeto"
    type=string  
}

variable "environment" {
  description = "Ambiente do Recurso"
  type        = string
  default     = "test"
}