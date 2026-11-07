
variable "name" {
  description = "Name of the Elastic IP"
  type        = string
}

variable "instance_id" {
  description = "EC2 instance ID for EIP association"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the Elastic IP"
  type        = map(string)
  default     = {}
}
