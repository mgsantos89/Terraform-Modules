
resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  associate_public_ip_address = var.associate_public_ip_address

  vpc_security_group_ids = var.security_group_ids
  key_name               = var.key_name

  placement_group            = var.placement_group
  placement_partition_number = var.placement_partition_number

  user_data                   = var.user_data
  user_data_base64            = var.user_data_base64
  user_data_replace_on_change = var.user_data_replace_on_change

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = var.metadata_http_tokens
    http_put_response_hop_limit = var.metadata_http_put_response_hop_limit
  }

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(var.tags, {
    Name = var.name
  })

  lifecycle {
    precondition {
      condition     = var.placement_partition_number == null || var.placement_group != null
      error_message = "placement_partition_number exige que placement_group seja informado."
    }

    precondition {
      condition     = var.user_data == null || var.user_data_base64 == null
      error_message = "Informe apenas um entre user_data e user_data_base64."
    }
  }
}
