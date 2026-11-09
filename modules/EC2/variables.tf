
variable "name" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "subnet_id" {
  type = string
}

variable "associate_public_ip_address" {
  type    = bool
  default = false
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "key_name" {
  type    = string
  default = null
}

variable "root_volume_size" {
  type    = number
  default = 8
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "placement_group" {
  description = "Nome do Placement Group onde a instância será criada"
  type        = string
  default     = null
}

variable "placement_partition_number" {
  description = "Número da partição (somente para Placement Group com estratégia partition)"
  type        = number
  default     = null

  validation {
    condition = var.placement_partition_number == null ? true : (
      var.placement_partition_number >= 1 && var.placement_partition_number <= 7
    )
    error_message = "placement_partition_number deve estar entre 1 e 7."
  }
}
