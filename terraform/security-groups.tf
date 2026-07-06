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

resource "aws_security_group_rule" "allow_ec2_to_eks_api" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.public-kunle-sg.id  # your EC2's SG
  description              = "Allow EC2/Ansible to reach EKS API"
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

# ==============================================================================
# EKS Cluster-to-Node Communication Rules
# ==============================================================================

# Allow EKS cluster control plane to communicate with nodes
resource "aws_security_group_rule" "allow_cluster_to_nodes" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.public-kunle-sg.id
  source_security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  description              = "Allow EKS cluster control plane to communicate with nodes"
}

# Allow nodes to communicate with EKS cluster control plane (required for kubelet communication)
resource "aws_security_group_rule" "allow_nodes_to_cluster" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.public-kunle-sg.id
  source_security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  description              = "Allow nodes to communicate with EKS cluster control plane"
}

# Allow nodes to communicate with each other
resource "aws_vpc_security_group_ingress_rule" "allow_node_to_node" {
  security_group_id = aws_security_group.public-kunle-sg.id
  cidr_ipv4         = aws_vpc.vpc.cidr_block
  ip_protocol       = "-1"
  description       = "Allow nodes to communicate with each other"
}