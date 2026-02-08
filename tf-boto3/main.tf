provider "aws" {
  region = "eu-central-1"  # ✅ 明确指定区域
}

variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}  # 修改：从 subnet_1_cidr_block 改为 subnet_cidr_block
variable "avail_zone" {}
variable "env_prefix" {}
variable "instance_type" {}
variable "public_key_location" {}  # 修改：从 ssh_key 改为 public_key_location
variable "my_ip" {}
variable "image_name" {}  # 新增：匹配 tfvars 中的 image_name

data "aws_ami" "amazon-linux-image" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [var.image_name]  # 修改：使用变量而不是硬编码
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

output "ami_id" {
  value = data.aws_ami.amazon-linux-image.id
}

# VPC
resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}

# Subnet
resource "aws_subnet" "myapp-subnet-1" {
  vpc_id            = aws_vpc.myapp-vpc.id
  cidr_block        = var.subnet_cidr_block  # 修改：使用匹配的变量名
  availability_zone = var.avail_zone
  tags = {
    Name = "${var.env_prefix}-subnet-1"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id

  tags = {
    Name = "${var.env_prefix}-internet-gateway"
  }
}

# Route Table
resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }

  tags = {
    Name = "${var.env_prefix}-route-table"
  }
}

# Route Table Association
resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id      = aws_subnet.myapp-subnet-1.id
  route_table_id = aws_route_table.myapp-route-table.id
}

# Security Group
resource "aws_security_group" "myapp-sg" {
  name   = "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name = "${var.env_prefix}-sg"
  }
}

# SSH Key Pair - 使用文件内容
resource "aws_key_pair" "ssh-key" {
  key_name   = "myapp-key"
  public_key = file(var.public_key_location)  # 修改：使用 file() 读取公钥文件
}

# EC2 Instance 1
resource "aws_instance" "myapp-server" {
  ami                         = data.aws_ami.amazon-linux-image.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.ssh-key.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids      = [aws_security_group.myapp-sg.id]
  availability_zone           = var.avail_zone

  tags = {
    Name = "${var.env_prefix}-server"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e
              
              # 更新系统
              yum update -y
              
              # 安装 Docker（AL2 通用方法）
              yum install -y docker
              
              # 启动 Docker 服务
              systemctl start docker
              systemctl enable docker
              
              # 添加 ec2-user 到 docker 组
              usermod -aG docker ec2-user
              
              # 运行 Nginx 容器（后台运行）
              docker run -d -p 8080:80 --name nginx-server nginx
              EOF
}

# EC2 Instance 2
resource "aws_instance" "myapp-server-two" {
  ami                         = data.aws_ami.amazon-linux-image.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.ssh-key.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids      = [aws_security_group.myapp-sg.id]
  availability_zone           = var.avail_zone

  tags = {
    Name = "${var.env_prefix}-server-two"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e
              
              # 更新系统
              yum update -y
              
              # 安装 Docker（AL2 通用方法）
              yum install -y docker
              
              # 启动 Docker 服务
              systemctl start docker
              systemctl enable docker
              
              # 添加 ec2-user 到 docker 组
              usermod -aG docker ec2-user
              
              # 运行 Nginx 容器（后台运行）
              docker run -d -p 8080:80 --name nginx-server nginx
              EOF
}

# EC2 Instance 3
#resource "aws_instance" "myapp-server-three" {
#  ami                         = data.aws_ami.amazon-linux-image.id
#  instance_type               = var.instance_type
#  key_name                    = aws_key_pair.ssh-key.key_name
#  associate_public_ip_address = true
#  subnet_id                   = aws_subnet.myapp-subnet-1.id
#  vpc_security_group_ids      = [aws_security_group.myapp-sg.id]
#  availability_zone           = var.avail_zone
#
#  tags = {
#    Name = "${var.env_prefix}-server-three"
#  }
#
#  user_data = <<-EOF
#              #!/bin/bash
#              set -e
#              
#              # 更新系统
#              yum update -y
#              
#              # 安装 Docker（AL2 通用方法）
#              yum install -y docker
#              
#              # 启动 Docker 服务
#              systemctl start docker
#              systemctl enable docker
#              
#              # 添加 ec2-user 到 docker 组
#              usermod -aG docker ec2-user
#              
#              # 运行 Nginx 容器（后台运行）
#              docker run -d -p 8080:80 --name nginx-server nginx
#              EOF
#}
## Outputs
output "server-ip" {
  value = aws_instance.myapp-server.public_ip
}

output "server-two-ip" {
  value = aws_instance.myapp-server-two.public_ip
}


output "my_ami_id" {
  value = data.aws_ami.amazon-linux-image.id
}

output "ami_name" {
  value = data.aws_ami.amazon-linux-image.name
}

output "ami_architecture" {
  value = data.aws_ami.amazon-linux-image.architecture
}

output "ami_creation_date" {
  value = data.aws_ami.amazon-linux-image.creation_date
}
