data "aws_availability_zones" "available" {
  state = "available"
}

# ==============================================================================
# 1. Base IAM Security Roles
# ==============================================================================

# Cluster Role
resource "aws_iam_role" "eks_cluster" {
  name = "${var.vpc_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# Node Group Role
resource "aws_iam_role" "eks_nodes" {
  name = "${var.vpc_name}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_elb_full_access" {
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_nodes_ebs_csi" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.eks_nodes.name
}

# ==============================================================================
# 2. EKS Control Plane & Core Managed Compute Node Groups
# ==============================================================================

resource "aws_eks_cluster" "main" {
  name     = "${var.vpc_name}-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.public-kunle-subnet.id,
      aws_subnet.public-kunle-subnet-2.id
    ]
    endpoint_private_access = true
    endpoint_public_access  = true
  }
  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

resource "aws_launch_template" "eks_nodes" {
  name_prefix = "eks-nodes-"
  description = "Launch template for EKS nodes"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 100
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  network_interfaces {
    security_groups = [aws_security_group.public-kunle-sg.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "EKS-Node"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}







resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "main-nodes"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  
    subnet_ids      = [
    aws_subnet.public-kunle-subnet.id,
    aws_subnet.public-kunle-subnet-2.id
  ]
  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 2
  }

  instance_types = ["t3.small"] # EKS nodes usually need more RAM than t2.micro

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_registry_policy
#   ,aws_route.private_nat # <--- CRITICAL: Wait for internet access
  ]
}


#resource "aws_eks_node_group" "main" {
#  cluster_name    = aws_eks_cluster.main.name
#  node_group_name = "main-nodes"
#  node_role_arn   = aws_iam_role.eks_nodes.arn
#  subnet_ids      = [
#    aws_subnet.public-kunle-subnet.id,
#    aws_subnet.public-kunle-subnet-2.id
#  ]
#  scaling_config {
#    desired_size = 4
#    max_size     = 5
#    min_size     = 2
#  }

#  instance_types = ["t3.small"]
  
#  launch_template {
#    id      = aws_launch_template.eks_nodes.id
#    version = "$Latest"
#  }

#  depends_on = [
#    aws_iam_role_policy_attachment.eks_worker_node_policy,
#    aws_iam_role_policy_attachment.eks_cni_policy,
#    aws_iam_role_policy_attachment.eks_registry_policy,
#    aws_security_group_rule.allow_cluster_to_nodes,
#    aws_security_group_rule.allow_nodes_to_cluster
#  ]
#  tags = {
#    Name = "Kubernetes-node"
#  }
#}

# Allow EKS Nodes to access PostgreSQL RDS
resource "aws_security_group_rule" "allow_eks_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.private-kunle-sg.id 
  source_security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

# ==============================================================================
# 3. OIDC Setup & EBS CSI Driver Engine Configuration
# ==============================================================================

data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_role" "ebs_csi_role" {
  name = "${var.vpc_name}-ebs-csi-driver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_role.name
}


resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_role.arn

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.ebs_csi_policy,
    aws_iam_role_policy_attachment.eks_nodes_ebs_csi
  ]
}