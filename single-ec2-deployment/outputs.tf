output "instance_ips" {
  value = [for instance in aws_instance.terra-ansible : instance.private_ip]
}