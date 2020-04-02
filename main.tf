provider "aws" {
    region = "${var.aws_region}"
}


# Creating a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Creating a Public subnet to Launch Public facing instances on
resource "aws_subnet" "main" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public"
  }
}

# Creating a Private subnet to launch private instances on
resource "aws_subnet" "second" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "Private"
  }
}

#creating an internet gateway for my vpc
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.main.id}"
}

#Granting the VPC internet access on it's route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.main.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}


# Setting up security group for ELB to have access to the internet
resource "aws_security_group" "elb" {
  name        = "terraform_elb_sg"
  description = "Load balancing traffic"
  vpc_id      = "${aws_vpc.main.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# allowing HTTP and SSH access for the instances
resource "aws_security_group" "default" {
  name        = "terraform_sg"
  description = "HTTP & SSH access"
  vpc_id      = "${aws_vpc.main.id}"

  #SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_elb" "web" {
  name = "terraform-elb"

  subnets         = ["${aws_subnet.main.id}"]
  security_groups = ["${aws_security_group.elb.id}"]
  instances       = ["${aws_instance.web.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}


resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  
}

resource "aws_instance" "web" {
  connection {
    user = "ubuntu"
    host = "${self.public_ip}"
  }


  instance_type = "t2.micro"

  ami = "${lookup(var.aws_amis, var.aws_region)}"

  key_name = "${aws_key_pair.auth.id}"


  #Security group allowing HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.default.id}"]


  
  subnet_id = "${aws_subnet.main.id}"

  # running a remote provisioner on the instance and installing nginx
  

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install nginx",
      "sudo service nginx start",
    ]
  }
}







































