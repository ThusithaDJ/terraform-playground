variable "access_key" {
  type = string
  description = "(optional) describe your variable"
}
variable "secret_key" {
  type = string
  description = "(optional) describe your variable"
}

provider "aws" {
  region = "us-east-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_instance" "my-first-server" {
  ami           = "ami-0ab4d1e9cf9a1215a"
  instance_type = "t2.micro"

  tags = {
    "name" = "aws-linux-server"
  }
}

resource "aws_vpc" "dev" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name" = "dev-vpc"
  }
}

resource "aws_subnet" "dev-subnet" {
  vpc_id = aws_vpc.dev.id
  cidr_block = "10.0.1.0/24"
  tags = {
    "Name" = "dev-subnet"
  }
}