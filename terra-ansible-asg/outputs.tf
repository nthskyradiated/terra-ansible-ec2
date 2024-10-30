# output "pumpFactoryPublicIP" {
#     value = aws_instance.pumpFactory.public_ip
#     description = "The public IP address of the web server"
#     sensitive = false
# }

# output "aws_instance_id" {
#     value = aws_instance.pumpFactory.id
#     description = "The ID of the web server"
#     sensitive = false
  
# }

# output "alb_dns_name" {
#     value = aws_lb.PF_LB.dns_name
#     description = "The domain name of the load balancer"
#     sensitive = false
# }