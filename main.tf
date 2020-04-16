provider "aws" {
  profile = "terraform_example"
  region  = "ap-northeast-1"
}

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "terraform-example"
  }
}

resource "aws_subnet" "public-a" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "terraform-example-public-a"
  }
}

resource "aws_subnet" "private-a" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "terraform-example-private-a"
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "terraform-example-igw"
  }
}

resource "aws_route_table" "public-route" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "terraform-example-route"
  }
}

resource "aws_route_table_association" "route-public-a" {
  subnet_id      = aws_subnet.public-a.id
  route_table_id = aws_route_table.public-route.id
}

resource "aws_s3_bucket" "main_bucket" {
  bucket = "terraform-example-20200416"
  acl    = "private"

  tags = {
    Name = "terraform-example"
  }
}

resource "aws_instance" "web" {
  ami                         = "ami-0f310fced6141e627"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public-a.id
  associate_public_ip_address = "true"

  vpc_security_group_ids = [aws_security_group.ssh_http.id]

  key_name = "terraform_example"

  tags = {
    Name = "terraform-example-web-server"
  }
}

resource "aws_security_group" "ssh_http" {
  name   = "ssh_http_sg"
  vpc_id = aws_vpc.main_vpc.id

  # https
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  # http
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ssh
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-example-sg"
  }
}

resource "aws_eip" "web_eip" {
  instance = aws_instance.web.id
  vpc      = true
}