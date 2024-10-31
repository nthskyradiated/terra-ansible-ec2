provider "aws" {
  region = "us-east-1"
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.69.0"
    }
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "ansible-key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM5KnlGIOuJXF+rm22VqIZx6DfzOA49A1t6s9Civ6DGl andy.pandaan@outlook.com"
}
resource "aws_launch_configuration" "terra-ansible" {
  image_id        = "ami-0e86e20dae9224db8"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instance.id]
  key_name        = "ansible-key"
  user_data       = <<-EOF
        #!/bin/bash
        echo "<html><h1>terra ansible</h1></html>" > index.html
        nohup busybox httpd -f -p ${var.server_port} &
        EOF

  lifecycle {
    create_before_destroy = true
  }


}
# resource "aws_instance" "terra-ansible" {
#   ami = "ami-0e86e20dae9224db8"
#   instance_type = "t2.micro"
#   vpc_security_group_ids = [aws_security_group.instance.id]

#   user_data = <<-EOF
#         #!/bin/bash
#         echo "<html><h1>terra-ansible</h1></html>" > index.html
#         nohup busybox httpd -f -p ${var.server_port} &
#         EOF

# user_data_replace_on_change = true

#   tags = {
#     Name = "terra-ansible"
#   }
# }

resource "aws_security_group" "instance" {
  name = "terra-ansible-web"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_autoscaling_group" "terra-ansible-asg" {
  launch_configuration = aws_launch_configuration.terra-ansible.name
  vpc_zone_identifier  = data.aws_subnets.default.ids
  target_group_arns    = [aws_lb_target_group.TA_TargetGroup.arn]
  health_check_type    = "ELB"
  min_size             = 4
  max_size             = 7

  tag {
    key                 = "Name"
    value               = "terra-ansible-asg"
    propagate_at_launch = true
  }

}

resource "aws_lb" "PF_LB" {
  name               = "terra-ansible-LB"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.TA_SecurityGroup.id]
}

resource "aws_lb_listener" "TA_LB_Listener" {
  load_balancer_arn = aws_lb.PF_LB.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }

}

resource "aws_security_group" "TA_SecurityGroup" {
  name = "terra-ansible-security-group"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_lb_target_group" "TA_TargetGroup" {
  name     = "terra-ansible-target-group"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

}

resource "aws_lb_listener_rule" "TA_LB_Listener_Rule" {
  listener_arn = aws_lb_listener.TA_LB_Listener.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TA_TargetGroup.arn
  }
}
