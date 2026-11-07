
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
