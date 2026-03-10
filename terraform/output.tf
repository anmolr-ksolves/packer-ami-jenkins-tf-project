output "instance_ip" {
  value = aws_instance.web.public_ip
}

output "instance_id" {
  value = aws_instance.web.id
}

output "ssh_command" {
  value = "ssh -i \"anmol-keypair.pem\" ubuntu@${aws_instance.web.public_dns}"
}

output "security_group_id" {
  value = local.web_sg_id
}