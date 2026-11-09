
resource "aws_placement_group" "this" {
  name     = var.name
  strategy = var.strategy

  # Applicable to partition strategy
  partition_count = var.strategy == "partition" ? var.partition_count : null

  # Applicable to spread strategy
  spread_level = var.strategy == "spread" ? var.spread_level : null

  tags = merge(var.tags, {
    Name = var.name
  })
}
