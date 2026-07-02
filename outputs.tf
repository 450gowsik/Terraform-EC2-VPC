output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet1" {
  value = aws_subnet.public1.id
}

output "private_subnet1" {
  value = aws_subnet.private1.id
}

output "ec2_instance_id" {
  value = aws_instance.web.id
}

output "ec2_public_ip" {
  value = aws_instance.web.public_ip
}