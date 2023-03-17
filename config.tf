terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.57.1"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.public_key
}

resource "aws_instance" "build" {
  ami           = "ami-0e067cc8a2b58de59"
  instance_type = "t2.micro"
  key_name      = "deployer-key"
  vpc_security_group_ids = ["sg-09497a8983bc03a7a"]

  tags = {
    Name = "build"
  }

    connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = var.public_key
    timeout     = "2m"
  }

    provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y maven git default-jdk awscli",
      "git clone https://github.com/boxfuse/boxfuse-sample-java-war-hello.git /usr/src/boxfuse",
      "cd /usr/src/boxfuse",
      "sudo maven package",
      "aws codeartifact push-package --repository https://msk-914838084400.d.codeartifact.eu-central-1.amazonaws.com/maven/newrepo/ --namespace example --package example-package --version 1.0.0 --source /usr/src/boxfuse/target/hello-1.0.war"
    ]
}
}

resource "aws_instance" "web" {
  ami           = "ami-0e067cc8a2b58de59"
  instance_type = "t2.micro"
  key_name      = "deployer-key"
  vpc_security_group_ids = ["sg-09497a8983bc03a7a"]

  tags = {
    Name = "web"
  }

    connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = var.public_key
    timeout     = "2m"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y default-jdk awscli tomcat",
    ]
  }
}

