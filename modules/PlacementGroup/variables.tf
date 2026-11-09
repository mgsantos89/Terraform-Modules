
variable "name" {
  description = "Placement Group name"
  type        = string
}

variable "strategy" {
  description = "Placement strategy: cluster, spread or partition"
  type        = string

  validation {
    condition = contains(
      ["cluster", "spread", "partition"],
      var.strategy
    )
    error_message = "Strategy must be cluster, spread or partition."
  }
}

variable "partition_count" {
  description = "Number of partitions for partition strategy"
  type        = number
  default     = null

  validation {
    condition = var.partition_count == null ? true : (
      var.partition_count >= 1 && var.partition_count <= 7
    )
    error_message = "Partition count must be between 1 and 7."
  }
}

variable "spread_level" {
  description = "Spread level: host or rack"
  type        = string
  default     = "rack"

  validation {
    condition     = contains(["host", "rack"], var.spread_level)
    error_message = "Spread level must be host or rack."
  }
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
