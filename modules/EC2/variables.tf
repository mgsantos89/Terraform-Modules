
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

variable "user_data" {
  description = "Script de User Data em texto puro (shell ou cloud-init). Não use junto com user_data_base64. Não coloque segredos aqui: o conteúdo fica no state e na metadata da instância."
  type        = string
  default     = null
}

variable "user_data_base64" {
  description = "User Data já codificado em base64 (ex.: saída gzip do data source cloudinit_config). Não use junto com user_data."
  type        = string
  default     = null
}

variable "user_data_replace_on_change" {
  description = "Se true, recria a instância quando o User Data mudar. Se false, a mudança é aplicada sem recriar, mas o script não roda de novo."
  type        = bool
  default     = false
}

variable "metadata_http_tokens" {
  description = "Uso de token no Instance Metadata Service. \"required\" exige IMDSv2; \"optional\" também aceita IMDSv1."
  type        = string
  default     = "required"

  validation {
    condition     = contains(["required", "optional"], var.metadata_http_tokens)
    error_message = "metadata_http_tokens deve ser \"required\" ou \"optional\"."
  }
}

variable "metadata_http_put_response_hop_limit" {
  description = "Hop limit da resposta PUT do IMDS. Use 1 para instâncias comuns e 2 quando containers (Docker/EKS) precisarem acessar a metadata."
  type        = number
  default     = 1

  validation {
    condition     = var.metadata_http_put_response_hop_limit >= 1 && var.metadata_http_put_response_hop_limit <= 64
    error_message = "metadata_http_put_response_hop_limit deve estar entre 1 e 64."
  }
}
