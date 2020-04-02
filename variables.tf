variable "key_name" {
  description = "terraformkey"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "eu-west-2"
}

# Ubuntu Precise 12.04 LTS (x64)
variable "aws_amis" {
  default = {
    eu-west-2 = "ami-7ad7c21e"
  }
}
