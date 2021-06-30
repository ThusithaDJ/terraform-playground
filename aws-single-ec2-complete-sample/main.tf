terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  access_key = ""
  secret_key = ""
}

# Pre - Create a keypair in EC2 Key Pairs
# 1. Create vpc
resource "aws_vpc" "terra-vpc-test" {
  cidr_block = "10.0.0.0/16"
}

# 2. Create Internet Gateway

resource "aws_internet_gateway" "terra-ig-test" {
  vpc_id = aws_vpc.terra-vpc-test.id

  tags = {
    "Name" = "Terraform test IG"
  }
}

# 3. Create Custom Route Table

resource "aws_route_table" "terra-rt-test" {
  vpc_id = aws_vpc.terra-vpc-test.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terra-ig-test.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.terra-ig-test.id
  }

  tags = {
    "Name" = "Terraform test RT"
  }
}

# 4. Create a subnet

resource "aws_subnet" "terra-subnet01-test" {
  vpc_id = aws_vpc.terra-vpc-test.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    "Name" = "Terraform test subnet01"
  }
}

# 5. Associate subnet with Route Table

resource "aws_route_table_association" "terra-rt-association01" {
  subnet_id = aws_subnet.terra-subnet01-test.id
  route_table_id = aws_route_table.terra-rt-test.id
}

# 6. Create security group to allow port 22, 80, 443
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.terra-vpc-test.id
    # ingress - inbound traffic
  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

# 7. Create a network interface with an IP in the subnet that was created in step 4

resource "aws_network_interface" "terra-web-server-ni" {

  subnet_id       = aws_subnet.terra-subnet01-test.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}

# 8. Assign an elastic IP to the network interface create in step 7

resource "aws_eip" "lb" {
  vpc = true
  network_interface = aws_network_interface.terra-web-server-ni.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [
    aws_internet_gateway.terra-ig-test
  ]
}

# 9. Create Ubuntu server and install/enable apache2

resource "aws_instance" "terra-ec2-web-test" {
  ami           = "ami-09e67e426f25ce0d7"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "terraform-demo"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.terra-web-server-ni.id
  }

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo your very first web server > /var/www/html/index.html'
                EOF

  tags = {
    "name" = "-terraform-aws-ubuntu-server"
  }
}
