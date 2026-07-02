resource "aws_security_group" "ec2_sg" {
  name        = "ec2-security-group"
  description = "Allow SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"

    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"

    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {

    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EC2-SG"
  }
}

resource "aws_instance" "web" {

  ami           = "ami-0c02fb55956c7d316"
  instance_type = var.instance_type

  subnet_id = aws_subnet.public1.id

  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id
  ]

  associate_public_ip_address = true

  key_name = var.key_name

  tags = {
    Name = "Terraform-EC2"
  }
}