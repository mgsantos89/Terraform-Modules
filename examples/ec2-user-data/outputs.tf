output "instance_id" {
  value = module.ec2.instance_id
}

output "public_ip" {
  value = module.ec2.public_ip
}

output "url" {
  description = "Endereço da página servida pelo nginx instalado via User Data"
  value       = "http://${module.ec2.public_ip}"
}
