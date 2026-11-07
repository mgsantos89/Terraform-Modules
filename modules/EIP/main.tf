
resource "aws_eip" "this" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_eip_association" "this" {
  count = var.instance_id != null ? 1 : 0

  allocation_id = aws_eip.this.id
  instance_id   = var.instance_id
}
