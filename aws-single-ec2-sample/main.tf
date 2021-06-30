provider "aws" {
  region = "us-east-1"
  access_key = "AKIAQ66CT2I46X4EUBET"
  secret_key = "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"
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