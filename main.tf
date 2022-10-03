#terraform provider is aws
# https://registry.terraform.io/browse/providers {hashicorp}. terraform 
#terraform language is known as hashicorn language (HCL)
provider "aws" {
    region = "us-east-1"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable env_prefix {}
variable avail_zone {}
variable my_ip {}
variable instance_type {}
variable public_key_location {}
variable private_key_location {}


#define the vpc for our resources
resource "aws_vpc" "development-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    name: "${var.env_prefix}-vpc"
  }
}
# define a subnet for our vpc
resource "aws_subnet" "dev-subnet" {
    vpc_id = aws_vpc.development-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
      name: "${var.env_prefix}-subnet"
    }
}

resource "aws_internet_gateway" "dev-internet-gateway" {
  vpc_id = aws_vpc.development-vpc.id
  tags = {
    Name: "${var.env_prefix}-ingway"
  }
}

resource "aws_route_table" "dev-route-table" {
  vpc_id = aws_vpc.development-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev-internet-gateway.id
  }
  tags = {
    Name: "${var.env_prefix}-rtb"
  }
}

resource "aws_route_table_association" "dev-rtassociation" {
  subnet_id = aws_subnet.dev-subnet.id
  route_table_id = aws_route_table.dev-route-table.id

}

resource "aws_security_group" "dev-security-group" {
  name ="dev-security-group"
  vpc_id = aws_vpc.development-vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
  tags = {
    Name: "${var.env_prefix}-security-group"
  }
  
}

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-*-x86_64-gp2"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  
}
resource "aws_instance" "dev-server-1" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type
  subnet_id = aws_subnet.dev-subnet.id
  vpc_security_group_ids = [aws_security_group.dev-security-group.id]
  availability_zone = var.avail_zone
  associate_public_ip_address = true
  key_name = aws_key_pair.ssh-key.key_name 

  #user_data = file("entry-script.sh")

  tags = {
    Name: "${var.env_prefix}-dev-server"
  }
}

# we can also automate the key pair for ssh using terraform
#  rather than creating it mannually from aws console

resource "aws_key_pair" "ssh-key" {
  key_name = "dev-server-key"
  public_key = "${file(var.public_key_location)}"
  
}

/* connection {
    type = "ssh"
    host = self.public_ip
    user = "ec2-user"
    private_key = file(var.private_key_location)
}

provisioner "remote-exec" {
    inline = [
        "export ENV=dev",
        "mkdir newdir"
    ]
}

provisioner "file" {
    source = "entry-script.sh"
    destination = "/home/ec2-user/entry-script.sh"

}

provisioner "remote-exec" {
     script = file("entry-script.sh")

} */