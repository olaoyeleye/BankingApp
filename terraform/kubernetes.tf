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


#data "aws_ssm_parameter" "eks_ami" {
#  name = "/aws/service/eks/optimized-ami/${aws_eks_cluster.main.version}/amazon-linux-2/recommended/image_id"
#}


resource "aws_launch_template" "eks_nodes" {
  name_prefix = "eks-nodes-"
  description = "Launch template for EKS nodes"
  #image_id      = data.aws_ssm_parameter.eks_ami.value  
  instance_type = "t3.small"
  
    metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2          # ← critical fix - must be 2+ for pods
  }

#  block_device_mappings {
#    device_name = "/dev/xvda"
#    ebs {
#      volume_size           = 100
#      volume_type           = "gp3"
#      delete_on_termination = true
#    }
#  }

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
  ami_type        = "AL2023_x86_64_STANDARD" 
  disk_size       = 100  


  subnet_ids      = [
    aws_subnet.public-kunle-subnet.id,
    aws_subnet.public-kunle-subnet-2.id
  ]
  scaling_config {
    desired_size = 3
    max_size     = 4
    min_size     = 3
  }

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = "$Latest"
  }

  

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_registry_policy
  ]
}

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

# ==============================================================================
# 4. AWS Load Balancer Controller IAM & Helm Installation
# ==============================================================================

# 4a. Create the IAM Role for the Load Balancer Controller
resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "${var.vpc_name}-aws-load-balancer-controller-role"

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
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
}

# 4b. Create the AWS Load Balancer Controller IAM Policy
resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "${var.vpc_name}-AWSLoadBalancerControllerIAMPolicy"
  description = "IAM Policy for AWS Load Balancer Controller"
  policy      = file("${path.module}/iam_policy.json") 
}

# 4c. Attach the Policy to the Role
resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
  role       = aws_iam_role.aws_load_balancer_controller.name
}

# 4d. Automatically deploy the Controller Pods into EKS via Helm
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.2"

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
    name  = "vpcId"
    value = aws_vpc.vpc.id          # ← add this - explicitly pass VPC ID
  }

  set {
    name  = "region"
    value = var.region              # ← also pass region explicitly
  }
  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.aws_load_balancer_controller
  ]
}