resource "aws_eks_cluster" "main" {
  name     = "${var.vpc_name}-cluster"
  role_arn = data.aws_iam_role.eks_cluster.arn
  version  = "1.31"

  vpc_config {
    subnet_ids = [
      aws_subnet.public-kunle-subnet.id,
      aws_subnet.public-kunle-subnet-2.id,
      aws_subnet.private-kunle-subnet.id
    ]
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Name = "${var.vpc_name}-cluster"
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.vpc_name}-node-group"
  node_role_arn   = data.aws_iam_role.eks_nodes.arn

  subnet_ids = [
    aws_subnet.public-kunle-subnet.id,
    aws_subnet.public-kunle-subnet-2.id
  ]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 3
  }

  instance_types = [var.instance_type]
  ami_type       = "AL2_x86_64"  #"AL2_x86_64"
  capacity_type  = "ON_DEMAND"

  depends_on = [
    aws_iam_role_policy_attachment.eks_nodes_worker_policy,
    aws_iam_role_policy_attachment.eks_nodes_cni_policy,
    aws_iam_role_policy_attachment.eks_nodes_ecr_policy,
    aws_eks_cluster.main
  ]

  tags = {
    Name = "${var.vpc_name}-node-group"
  }
}
 #resource "aws_eks_addon" "ebs_csi" {
 # cluster_name             = aws_eks_cluster.main.name
 # addon_name               = "aws-ebs-csi-driver"
 # service_account_role_arn = aws_iam_role.ebs_csi_role.arn

 # resolve_conflicts_on_create = "OVERWRITE"
 # resolve_conflicts_on_update = "OVERWRITE"

 # timeouts {
 #   create = "10m"
 #   update = "10m"
 #   delete = "10m"
 # }

 # depends_on = [
 #   aws_eks_node_group.main,
 #   aws_iam_role_policy_attachment.ebs_csi_policy,
 #   aws_iam_role_policy_attachment.eks_nodes_ebs_csi
 # ]
#}

resource "helm_release" "ebs_csi_driver" {
  name       = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  namespace  = "kube-system"
  version    = "2.30.0"

  wait            = true
  timeout         = 900
  atomic          = false
  cleanup_on_fail = false

  set {
    name  = "controller.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "controller.serviceAccount.name"
    value = "ebs-csi-controller-sa"
  }

  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.ebs_csi_role.arn
  }

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.ebs_csi_policy,
    aws_iam_openid_connect_provider.eks
  ]
}




# EBS CSI IAM Role
resource "aws_iam_role" "ebs_csi_role" {
  name = "${var.vpc_name}-ebs-csi-role"

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

resource "aws_iam_role_policy_attachment" "eks_nodes_ebs_csi" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = data.aws_iam_role.eks_nodes.name
}

# OIDC Provider (needed by ebs_csi_role above)
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}


