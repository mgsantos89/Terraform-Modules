variable "instance_name" {
  description = "Nome da Instancia"
  type = string
}

variable "ami_id" {
  description = "ID da AMI"
  type = string
}

variable "instance_type" {
  description = "Tipo de Instancia"
  type = string
  default = "t3.medium"
}
variable "subnet_id" {
  description = "ID da Subnet"
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