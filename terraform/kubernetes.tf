data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# ==============================================================================
# 1. Base IAM Roles
# ==============================================================================

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

# ==============================================================================
# 2. EKS Cluster and Node Group
# ==============================================================================

resource "aws_eks_cluster" "main" {
  name     = "${var.vpc_name}-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  vpc_config {
    subnet_ids = [
      aws_subnet.public-kunle-subnet.id,
      aws_subnet.public-kunle-subnet-2.id
    ]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

resource "aws_eks_access_entry" "ci_admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = data.aws_caller_identity.current.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "ci_admin_policy" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = data.aws_caller_identity.current.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.ci_admin]
}

resource "aws_eks_access_entry" "node_role" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.eks_nodes.arn
  type          = "EC2_LINUX"
}

#resource "aws_launch_template" "eks_nodes" {
#  name_prefix   = "eks-nodes-"
#  description   = "Launch template for EKS nodes"
#  instance_type = "t3.medium"

#  metadata_options {
#    http_endpoint               = "enabled"
#    http_tokens                 = "required"
#    http_put_response_hop_limit = 2
#  }

#  block_device_mappings {
#    device_name = "/dev/xvda"
#    ebs {
#      volume_size           = 100
#      volume_type           = "gp3"
#      delete_on_termination = true
#    }
#  }

#  network_interfaces {
#    security_groups = [aws_security_group.public-kunle-sg.id]
#  }

#  tag_specifications {
#    resource_type = "instance"
#    tags = {
#      Name = "EKS-Node"
#    }
#  }

#  lifecycle {
#    create_before_destroy = true
#  }
#}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "main-nodes"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  ami_type        = "AL2023_x86_64_STANDARD"
  instance_typs = ["t3.micro"]


  subnet_ids = [
    aws_subnet.public-kunle-subnet.id,
    aws_subnet.public-kunle-subnet-2.id
  ]

  scaling_config {
    desired_size = 3
    max_size     = 4
    min_size     = 3
  }

  update_config {
    max_unavailable = 1
  }

#  launch_template {
#    id      = aws_launch_template.eks_nodes.id
#    version = "$Latest"
#  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_registry_policy,
    aws_eks_access_entry.node_role
  ]
}

resource "aws_security_group_rule" "allow_eks_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.private-kunle-sg.id
  source_security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

# ==============================================================================
# 3. OIDC + EBS CSI Driver IAM Role
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
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
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

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.ebs_csi_policy,
    aws_iam_openid_connect_provider.eks
  ]

  timeouts {
    create = "40m"
    update = "40m"
    delete = "20m"
  }
}

# ==============================================================================
# 4. AWS Load Balancer Controller IAM + Helm
# ==============================================================================

resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "${var.vpc_name}-aws-load-balancer-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "${var.vpc_name}-AWSLoadBalancerControllerIAMPolicy"
  description = "IAM Policy for AWS Load Balancer Controller"
  policy      = file("${path.module}/iam_policy.json")
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
  role       = aws_iam_role.aws_load_balancer_controller.name
}

resource "helm_release" "aws_load_balancer_controller" {
  name              = "aws-load-balancer-controller"
  repository        = "https://aws.github.io/eks-charts"
  chart             = "aws-load-balancer-controller"
  namespace         = "kube-system"
  version           = "1.7.2"
  create_namespace  = false
  wait              = true
  timeout           = 900
  atomic            = false
  cleanup_on_fail   = false

  set {
    name  = "clusterName"
    value = aws_eks_cluster.main.name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_load_balancer_controller.arn
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = aws_vpc.vpc.id
  }

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.aws_load_balancer_controller,
    aws_eks_addon.ebs_csi
  ]
}