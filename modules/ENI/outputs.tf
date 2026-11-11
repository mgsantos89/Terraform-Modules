
output "eni_id" {
  description = "Network Interface ID"
  value       = aws_network_interface.this.id
}

output "eni_arn" {
  description = "Network Interface ARN"
  value       = aws_network_interface.this.arn
}

output "mac_address" {
  description = "ENI MAC address"
  value       = aws_network_interface.this.mac_address
}

output "private_ips" {
  description = "Private IP addresses"
  value       = aws_network_interface.this.private_ips
}

output "private_dns_name" {
  description = "Private DNS name"
  value       = aws_network_interface.this.private_dns_name
}

output "attachment_id" {
  description = "ENI attachment ID"
  value       = try(aws_network_interface_attachment.this[0].id, null)
}
