variable "prefixo_projeto" {
    description = "Prefixo do Projeto"
    type=string  
}

variable "environment" {
  description = "Ambiente do Recurso"
  type        = string
  default     = "test"
}