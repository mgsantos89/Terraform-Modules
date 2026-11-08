
variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
}

variable "private_key_path" {
  description = "Local path to save the PEM file"
  type        = string
  default     = "keys/lab-key.pem"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
