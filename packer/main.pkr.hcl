packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "nginx" {
  region        = "ap-south-1"
  source_ami    = "ami-019715e0d74f695be"
  instance_type = "t3.micro"
  ssh_username  = "ubuntu"

  ami_name = "nginx-ami-${local.timestamp}"

  tags = {
    Name      = "packer-nginx"
    CreatedBy = "Packer"
  }
}

build {
  sources = ["source.amazon-ebs.nginx"]

  provisioner "shell" {
    script = "scripts/install_nginx.sh"
  }

  post-processor "manifest" {
    output = "manifest.json"
  }
}
