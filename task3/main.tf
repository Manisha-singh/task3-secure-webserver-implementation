provider "aws" {
  region    = "ap-south-1"
  profile   = "mannu"
}

resource "aws_vpc" "main" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_support="true"
  tags = {
    Name = "main"
  }
}
resource "aws_subnet" "public-subnet" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "192.168.0.0/24"
  availability_zone="ap-south-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private-subnet" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "192.168.1.0/24"
  map_public_ip_on_launch = "false"
  availability_zone="ap-south-1a"
  tags = {
    Name = "private-subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"
  tags = {
    Name = "gateway"
  }
}

resource "aws_route_table" "public-route" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  tags = {
    Name = "public-route"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = "${aws_subnet.public-subnet.id}"
  route_table_id = "${aws_route_table.public-route.id}"
}

resource "aws_route_table" "private-route" {
  vpc_id = "${aws_vpc.main.id}"
 
  tags = {
    Name = "private-route"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = "${aws_subnet.private-subnet.id}"
  route_table_id = "${aws_route_table.private-route.id}"
}

resource "aws_security_group" "wordpress-security" {
  name        = "wordpress-security"
  description = "Allow HTTP security"
  vpc_id      = "${aws_vpc.main.id}"
   ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "wordpress-security"
  }
}

resource "aws_security_group" "mysql-security" {
  name        = "mysql-security"
  description = "Allow MYSQL inbound traffic"
  vpc_id      = "${aws_vpc.main.id}"
   ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  ingress {
    description = "MYSQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysql-security"
  }
}

resource "aws_instance" "wordpress" {
  ami          = "ami-0c7f2154fde8c7f1b"
  instance_type = "t2.micro"
  key_name = "keypair"
  vpc_security_group_ids= ["${aws_security_group.wordpress-security.id}",]
  associate_public_ip_address= "true"
  availability_zone="ap-south-1a"
  subnet_id      = "${aws_subnet.public-subnet.id}"
  tags = {
    Name = "wordpress-os"
 }
}

resource "aws_instance" "mysql" {
  ami          = "ami-0ba1b89cd16fe686c"
  instance_type = "t2.micro"
  key_name = "keypair"
  vpc_security_group_ids= ["${aws_security_group.mysql-security.id}",]
  associate_public_ip_address= "false"
  subnet_id      = "${aws_subnet.private-subnet.id}"
  availability_zone="ap-south-1a"

  tags = {
    Name = "mysql-os"
 }
}

