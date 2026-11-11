
variable "name" {
  description = "ENI name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet where the ENI will be created"
  type        = string
}

variable "description" {
  description = "ENI description"
  type        = string
  default     = "Managed by Terraform"
}

variable "private_ips" {
  description = "Private IPv4 addresses assigned to the ENI"
  type        = list(string)
  default     = null
}

variable "security_group_ids" {
  description = "Security Groups associated with the ENI"
  type        = list(string)
  default     = []
}

variable "source_dest_check" {
  description = "Enable source/destination checking"
  type        = bool
  default     = true
}

variable "instance_id" {
  description = "EC2 instance ID for optional ENI attachment"
  type        = string
  default     = null
}

variable "device_index" {
  description = "Device index for secondary ENI attachment"
  type        = number
  default     = 1

  validation {
    condition     = var.device_index >= 1
    error_message = "Device index must be at least 1 for secondary ENI attachment."
  }
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
