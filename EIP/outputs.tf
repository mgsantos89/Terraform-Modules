output "allocation_id" {
  value = aws_eip.this.id
}

output "public_ip" {
  value = aws_eip.this.public_ip
}

output "association_id" {
  value = var.instance_id != null ? aws_eip_association.this[0].id : null
}
