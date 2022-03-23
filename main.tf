#terraform provider is aws
provider "aws" {
    region = "us-east-1"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable env_prefix {}

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
    availability_zone = "us-east-1a" 
    tags = {
      name: "${var.env_prefix}-subnet"
    }
}
