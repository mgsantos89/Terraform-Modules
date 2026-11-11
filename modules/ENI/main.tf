
resource "aws_network_interface" "this" {
  subnet_id       = var.subnet_id
  private_ips     = var.private_ips
  security_groups = var.security_group_ids

  description = var.description

  source_dest_check = var.source_dest_check

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_network_interface_attachment" "this" {
  count = var.instance_id != null ? 1 : 0

  instance_id          = var.instance_id
  network_interface_id = aws_network_interface.this.id
  device_index         = var.device_index
}
