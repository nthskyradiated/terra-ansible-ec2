locals {
  ssh_user         = "ubuntu"
  key_name         = "ansible-key"
  private_key_path = "~/.ssh/ansible-key"
}

provider "aws" {
  region = "us-east-1"
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
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_key_pair" "deployer" {
  key_name   = local.key_name
  public_key = var.public_key
}

resource "aws_instance" "terra-ansible" {
  count                       = var.instance_count
  ami                         = "ami-0e86e20dae9224db8" # adjsust if needed
  instance_type               = "t2.micro" # adjust if needed
  vpc_security_group_ids      = [aws_security_group.terra-ansible-sg.id]
  key_name                    = local.key_name
  subnet_id                   = aws_subnet.terra-ansible-subnet.id
  associate_public_ip_address = true

  tags = {
    Name = "terra-ansible-${count.index}"
  }


  provisioner "remote-exec" {
    inline = ["echo 'Wait until SSH is ready'"]

    connection {
      type        = "ssh"
      user        = "ubuntu" # Adjust if needed
      private_key = file(local.private_key_path)
      host        = self.public_ip
    }
  }
}

# Null resource to trigger ansible-playbook run after instance creation
resource "terraform_data" "ansible_provision" {
  depends_on = [aws_instance.terra-ansible]

  provisioner "local-exec" {
    command = "ansible-playbook -i '${join(",", aws_instance.terra-ansible.*.public_ip)},' --private-key ${local.private_key_path} nginx.yaml"
  }
}


resource "null_resource" "write_inventory" {
  # This ensures that this resource depends on all instances being created
  depends_on = [aws_instance.terra-ansible]

  provisioner "local-exec" {
    command = "bash ./write_inventory.sh"
  }
}
