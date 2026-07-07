resource "aws_security_group" "public-kunle-sg" {
  name        = "public-kunle-sg"
  description = "Allow public inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "public-kunle-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_HTTPS" {
  security_group_id = aws_security_group.public-kunle-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Allow HTTPS"
}

resource "aws_vpc_security_group_ingress_rule" "allow_HTTP" {
  security_group_id = aws_security_group.public-kunle-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Allow HTTP"
}

resource "aws_vpc_security_group_ingress_rule" "allow_SSH" {
  security_group_id = aws_security_group.public-kunle-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "Allow SSH"
}

resource "aws_vpc_security_group_ingress_rule" "allow_user" {
  security_group_id = aws_security_group.public-kunle-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8000
  to_port           = 8000
  ip_protocol       = "tcp"
  description       = "Allow user service"
}

resource "aws_vpc_security_group_ingress_rule" "allow-activities" {
  security_group_id = aws_security_group.public-kunle-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8001
  to_port           = 8001
  ip_protocol       = "tcp"
  description       = "Allow activities service"
}

resource "aws_vpc_security_group_ingress_rule" "allow_transaction" {
  security_group_id = aws_security_group.public-kunle-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"
  description       = "Allow transaction service"
}

resource "aws_vpc_security_group_ingress_rule" "allow_postgress" {
  security_group_id = aws_security_group.public-kunle-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
  description       = "Allow PostgreSQL"
}

resource "aws_vpc_security_group_egress_rule" "allow-all-public-traffic" {
  security_group_id = aws_security_group.public-kunle-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic"
}

resource "aws_security_group" "private-kunle-sg" {
  name        = "private-kunle-sg"
  description = "Allow private inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "private-kunle-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow-postgreSQL" {
  security_group_id = aws_security_group.private-kunle-sg.id
  cidr_ipv4         = aws_vpc.vpc.cidr_block
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
  description       = "Allow PostgreSQL from VPC"
}

resource "aws_vpc_security_group_ingress_rule" "allow-private-SSH" {
  security_group_id = aws_security_group.private-kunle-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "Allow SSH"
}

resource "aws_vpc_security_group_egress_rule" "allow-all-private-traffic" {
  security_group_id = aws_security_group.private-kunle-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic"
}

resource "aws_vpc_security_group_ingress_rule" "allow_node_to_node" {
  security_group_id = aws_security_group.public-kunle-sg.id
  cidr_ipv4         = aws_vpc.vpc.cidr_block
  ip_protocol       = "-1"
  description       = "Allow internal VPC traffic"
}