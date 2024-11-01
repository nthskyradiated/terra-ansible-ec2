output "instance_ips" {
  value = [for instance in aws_instance.terra-ansible : instance.private_ip]
}
output "instance_public_ips" {
  value = [for instance in aws_instance.terra-ansible : instance.public_ip]
}

output "instance_ids" {
  value = [for instance in aws_instance.terra-ansible : instance.id]
}