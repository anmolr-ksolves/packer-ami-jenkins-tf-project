variable "region" {
  default = "ap-south-1"
}

variable "key_name" {
  description = "Existing EC2 Key Pair name to attach to instance"
  type        = string
  default     = "anmol-keypair"
}