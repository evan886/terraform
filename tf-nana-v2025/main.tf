provider "aws" {
  region     = "eu-central-1"


}

variable  "cidr_block"  {
  description = " cidr blocks and name tags for  vpc and subnets "
  type = list(object ({
    cidr_block = string
    name = string
  }))
}

resource "aws_vpc" "development-vpc" {
  cidr_block = var.cidr_block[0].cidr_block
  tags = {
    Name :var.cidr_block[0].name
  }
}

resource "aws_subnet" "dev-subnet-1" {
  vpc_id            = aws_vpc.development-vpc.id
  cidr_block        = var.cidr_block[1].cidr_block
  availability_zone = "eu-central-1a"
  tags = {
    Name : var.cidr_block[1].name
  }
}

data "aws_vpc" "existing_vpc" {
  default = true
}
# Name must be unique for each resource type (we cp from dev-subnet-1 to dev-subnet-2 and change the name of the resource)
resource "aws_subnet" "dev-subnet-2" {
  vpc_id            = data.aws_vpc.existing_vpc.id 
  cidr_block        = "172.31.48.0/20"
  availability_zone = "eu-central-1a"
  tags = {
    Name : "subnet-2-default"
  }
}

output "dev-vpc-id" {
  value = aws_vpc.development-vpc.id
}

output "dev-subnet-id" {
  value = aws_subnet.dev-subnet-1.id
}

#12.9  12:00 17:00

#terraform destroy -target=aws_subnet.dev-subnet-2

# Terraform encountered an error while generating this plan. 