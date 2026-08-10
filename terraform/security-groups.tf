resource "aws_security_group" "public_kunle_sg" {
  name        = "${var.vpc_name}-nodes-sg"
  description = "Security group for EKS nodes and public access where required"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_name}-nodes-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.public_kunle_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.public_kunle_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.public_kunle_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_public_traffic" {
  security_group_id = aws_security_group.public_kunle_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "database_sg" {
  name        = "${var.vpc_name}-database-sg"
  description = "Security group for in-cluster or external database access"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_name}-database-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_postgresql_from_vpc" {
  security_group_id = aws_security_group.database_sg.id
  cidr_ipv4         = aws_vpc.vpc.cidr_block
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432
}

resource "aws_vpc_security_group_egress_rule" "allow_all_database_traffic" {
  security_group_id = aws_security_group.database_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group_rule" "allow_cluster_to_nodes" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.public_kunle_sg.id
  source_security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  description              = "Allow EKS control plane to communicate with nodes"
}

resource "aws_security_group_rule" "allow_nodes_to_cluster" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.public_kunle_sg.id
  source_security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  description              = "Allow nodes to communicate with EKS control plane"
}

resource "aws_vpc_security_group_ingress_rule" "allow_node_to_node" {
  security_group_id = aws_security_group.public_kunle_sg.id
  cidr_ipv4         = aws_vpc.vpc.cidr_block
  ip_protocol       = "-1"
  description       = "Allow nodes to communicate with each other"
}