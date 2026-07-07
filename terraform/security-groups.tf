resource "aws_security_group" "public_kunle_sg" {
  name        = "public-kunle-sg"
  description = "Public security group"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "public-kunle-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.public_kunle_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.public_kunle_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.public_kunle_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_user" {
  security_group_id = aws_security_group.public_kunle_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8000
  to_port           = 8000
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_activities" {
  security_group_id = aws_security_group.public_kunle_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8001
  to_port           = 8001
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_transaction" {
  security_group_id = aws_security_group.public_kunle_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_postgres_public" {
  security_group_id = aws_security_group.public_kunle_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_public_traffic" {
  security_group_id = aws_security_group.public_kunle_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "private_kunle_sg" {
  name   = "private-kunle-sg"
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "private-kunle-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_postgresql_private" {
  security_group_id = aws_security_group.private_kunle_sg.id
  cidr_ipv4         = aws_vpc.vpc.cidr_block
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_private_ssh" {
  security_group_id = aws_security_group.private_kunle_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_private_traffic" {
  security_group_id = aws_security_group.private_kunle_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group_rule" "allow_ec2_to_eks_api" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.public_kunle_sg.id
  description              = "Allow EC2/Ansible to reach EKS API"
}

resource "aws_security_group_rule" "allow_cluster_to_nodes" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.public_kunle_sg.id
  source_security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  description              = "Allow EKS cluster control plane to communicate with nodes"
}

resource "aws_security_group_rule" "allow_nodes_to_cluster" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.public_kunle_sg.id
  source_security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  description              = "Allow nodes to communicate with EKS cluster control plane"
}

resource "aws_vpc_security_group_ingress_rule" "allow_node_to_node" {
  security_group_id = aws_security_group.public_kunle_sg.id
  cidr_ipv4         = aws_vpc.vpc.cidr_block
  ip_protocol       = "-1"
  description       = "Allow nodes to communicate with each other"
}