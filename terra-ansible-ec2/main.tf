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

# Create a VPC
resource "aws_vpc" "terra-ansible-vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create an Internet Gateway
resource "aws_internet_gateway" "terra-ansible-ig" {
  vpc_id = aws_vpc.terra-ansible-vpc.id
}

# Create a route table
resource "aws_route_table" "terra-ansible-rt" {
  vpc_id = aws_vpc.terra-ansible-vpc.id

  route {
    # Route traffic to the internet through the Internet Gateway
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terra-ansible-ig.id
  }
}

# Create a subnet and associate it with the route table
resource "aws_subnet" "terra-ansible-subnet" {
  vpc_id            = aws_vpc.terra-ansible-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  # Associate the subnet with the route table
  tags = {
    Name = "terra-ansible-subnet"
  }
}

resource "aws_route_table_association" "terra-ansible-rta" {
  subnet_id      = aws_subnet.terra-ansible-subnet.id
  route_table_id = aws_route_table.terra-ansible-rt.id
}

# Create a security group
resource "aws_security_group" "terra-ansible-sg" {
  name        = "terra-ansible-sg"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.terra-ansible-vpc.id

  # Allow inbound traffic on port 22
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all traffic within the security group
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Allow outbound traffic on all ports
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "ansible-key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM5KnlGIOuJXF+rm22VqIZx6DfzOA49A1t6s9Civ6DGl andy.pandaan@outlook.com"
}

resource "aws_instance" "terra-ansible" {
  count                 = 4
  ami                   = "ami-0e86e20dae9224db8"
  instance_type         = "t2.micro"
  vpc_security_group_ids = [aws_security_group.terra-ansible-sg.id]
  key_name              = "ansible-key"
  subnet_id             = aws_subnet.terra-ansible-subnet.id
  associate_public_ip_address = true  # Ensure public IP is assigned

  user_data = <<-EOF
        #!/bin/bash
        echo "<html><h1>terra-ansible</h1></html>" > index.html
        nohup busybox httpd -f -p ${var.server_port} &
        EOF

  user_data_replace_on_change = true

  tags = {
    Name = "terra-ansible-${count.index}"
  }
}
