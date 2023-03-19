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

#resource "aws_key_pair" "depkey" {
#  key_name   = "depkey"
#  public_key = var.public_key
#}

resource "aws_instance" "build" {
  ami           = "ami-0e067cc8a2b58de59"
  instance_type = "t2.micro"
  key_name      = "depkey"
  vpc_security_group_ids = ["sg-09497a8983bc03a7a"]

  tags = {
    Name = "build"
  }

    connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = self.public_ip
    timeout     = "2m"
  }

    provisioner "remote-exec" {
    inline = [
      "sudo sleep 1m",
      "sudo apt update",
      "sudo apt install -y maven default-jdk unzip",
      "sudo curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /usr/src/awscliv2.zip",
      "cd /usr/src && sudo unzip awscliv2.zip && sudo ./aws/install",
      "sudo git clone https://github.com/Vesna3517/boxfuse-sample-java-war-hello-copy.git /usr/src/boxfuse",
      "cd /usr/src/boxfuse",
      "sudo mvn package",
      "export AWS_ACCESS_KEY_ID=var.aws_access_key",
      "export AWS_SECRET_ACCESS_KEY=var.aws_secret_key",
      "export AWS_DEFAULT_REGION=eu-central-1",
      "sudo aws configure ",
      "export CODEARTIFACT_AUTH_TOKEN=`aws codeartifact get-authorization-token --domain msk --domain-owner 914838084400 --query authorizationToken --output text`",
      "cd /usr/src/boxfuse/target",
      "curl --request PUT https://msk-914838084400.d.codeartifact.eu-central-1.amazonaws.com/maven/newrepo/com/mycompany/app/my-app/1.0/hello-1.0.war --user "aws:$CODEARTIFACT_AUTH_TOKEN" --header "Cnewrepom" --data-binary @hello-1.0.war"
    ]
}
}
resource "aws_instance" "web" {
  ami           = "ami-0e067cc8a2b58de59"
  instance_type = "t2.micro"
  key_name      = "depkey"
  vpc_security_group_ids = ["sg-09497a8983bc03a7a"]

  tags = {
    Name = "web"
  }

    connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = var.public_key
    timeout     = "2m"
    host        = self.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "sudo sleep 1m",
      "sudo apt update",
      "sudo apt install -y unzip tomcat9",
      "sudo curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /usr/src/awscliv2.zip",
      "cd /usr/src && sudo unzip awscliv2.zip && sudo ./aws/install",
      "export AWS_ACCESS_KEY_ID=var.aws_access_key",
      "export AWS_SECRET_ACCESS_KEY=var.aws_secret_key",
      "export AWS_DEFAULT_REGION=eu-central-1",
      "sudo aws configure ",
      "export CODEARTIFACT_AUTH_TOKEN=`aws codeartifact get-authorization-token --domain msk --domain-owner 914838084400 --query authorizationToken --output text`",
      "sudo curl -u aws:$CODEARTIFACT_AUTH_TOKEN https://msk-914838084400.d.codeartifact.eu-central-1.amazonaws.com/maven/newrepo/com/mycompany/app/my-app/1.0/my-app-1.0.jar -o /var/lib/tomcat9/webapps/hello-1.0.war",
      "sudo systemctl restart tomcat9"
    ]
  }
}