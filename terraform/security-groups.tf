resource "aws_security_group" "public-kunle-sg" {
  name        = "public-kunle-sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "public-kunle-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_HTTPS" {
  security_group_id = aws_security_group.public-kunle-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}


resource "aws_vpc_security_group_ingress_rule" "allow_user" {
  security_group_id = aws_security_group.public-kunle-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8000
  ip_protocol       = "tcp"
  to_port           = 8000
}

resource "aws_vpc_security_group_ingress_rule" "allow-activities" {
  security_group_id = aws_security_group.public-kunle-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8001
  ip_protocol       = "tcp"
  to_port           = 8001
}

resource "aws_vpc_security_group_ingress_rule" "allow_transaction" {
  security_group_id = aws_security_group.public-kunle-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}
resource "aws_vpc_security_group_ingress_rule" "allow_postgress" {
  security_group_id = aws_security_group.public-kunle-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432
}
resource "aws_vpc_security_group_ingress_rule" "allow_HTTP" {
  security_group_id = aws_security_group.public-kunle-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_SSH" {
  security_group_id = aws_security_group.public-kunle-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow-all-public-traffic" {
  security_group_id = aws_security_group.public-kunle-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}






resource "aws_security_group" "private-kunle-sg" {
  name        = "private-kunle-sg" 
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "private-kunle-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow-postgreSQL" {
  security_group_id = aws_security_group.private-kunle-sg.id
  cidr_ipv4         = aws_vpc.vpc.cidr_block
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432
}

resource "aws_vpc_security_group_ingress_rule" "allow-private-SSH" {
  security_group_id = aws_security_group.private-kunle-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow-all-private-traffic" {
  security_group_id = aws_security_group.private-kunle-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}