
variable "name" {
  description = "Security Group name"
  type        = string
}

variable "description" {
  description = "Security Group description"
  type        = string
  default     = "Managed by Terraform"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "ingress_rules" {
  description = "Inbound security group rules"

  type = map(object({
    description                   = optional(string)
    from_port = optional(number)
    to_port   = optional(number)

    ip_protocol                   = string
    cidr_ipv4                     = optional(string)
    cidr_ipv6                     = optional(string)
    referenced_security_group_id  = optional(string)
    prefix_list_id                = optional(string)
  }))

  default = {}
}

variable "egress_rules" {
  description = "Outbound security group rules"

  type = map(object({
    description                   = optional(string)
    from_port = optional(number)
    to_port   = optional(number)

    ip_protocol                   = string
    cidr_ipv4                     = optional(string)
    cidr_ipv6                     = optional(string)
    referenced_security_group_id  = optional(string)
    prefix_list_id                = optional(string)
  }))

  default = {}
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
