provider "aws" {
  region     = "eu-central-1"


}

resource "aws_vpc" "development-vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "dev-subnet-1" {
  vpc_id            = aws_vpc.development-vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "eu-central-1a"
}

data "aws_vpc" "existing_vpc" {
  default = true
}
# Name must be unique for each resource type (we cp from dev-subnet-1 to dev-subnet-2 and change the name of the resource)
resource "aws_subnet" "dev-subnet-2" {
  vpc_id            = data.aws_vpc.existing_vpc.id 
  cidr_block        = "172.31.48.0/20"
  availability_zone = "eu-central-1a"
}



# Terraform encountered an error while generating this plan.