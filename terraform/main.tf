provider "aws" {
  region = var.region
}

data "aws_ssm_parameter" "ami" {
  name = "/nginx/latest-ami"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_security_groups" "existing_web" {
  filter {
    name   = "group-name"
    values = ["nginx-sg"]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

locals {
  web_sg_id = length(data.aws_security_groups.existing_web.ids) > 0 ? data.aws_security_groups.existing_web.ids[0] : aws_security_group.web[0].id
}

resource "aws_security_group" "web" {
  count       = length(data.aws_security_groups.existing_web.ids) == 0 ? 1 : 0
  name        = "nginx-sg"
  description = "Security group for nginx EC2"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_instance" "web" {
  ami           = data.aws_ssm_parameter.ami.value
  instance_type = "t3.micro"
  key_name      = var.key_name

  vpc_security_group_ids = [local.web_sg_id]

  tags = {
    Name = "nginx-server"
  }
}
