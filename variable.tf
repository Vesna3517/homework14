variable "aws_access_key" {
  type = string
  description = "AWS access key"
}

variable "aws_secret_key" {
  type = string
  description = "AWS secret key"
}

variable "public_key" {
  type = string
  description = "Name of the key pair to use for SSH access"
}

variable "private_key_path" {
  type = string
  description = "file location"
}