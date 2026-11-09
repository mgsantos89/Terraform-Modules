
output "placement_group_id" {
  description = "Placement Group ID"
  value       = aws_placement_group.this.id
}

output "placement_group_arn" {
  description = "Placement Group ARN"
  value       = aws_placement_group.this.arn
}

output "placement_group_name" {
  description = "Placement Group name"
  value       = aws_placement_group.this.name
}

output "placement_group_strategy" {
  description = "Placement Group strategy"
  value       = aws_placement_group.this.strategy
}
