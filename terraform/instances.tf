resource "aws_instance" "nginx" {
  ami                         = var.ami
  instance_type               = var.instance_type
  key_name                    = "${var.key_name}"
  associate_public_ip_address = true
  # security_groups = 
  subnet_id              = aws_subnet.public-kunle-subnet.id
  vpc_security_group_ids = [aws_security_group.public-kunle-sg.id]

  tags ={
    Name = var.instance-name-nginx
  }
}


 