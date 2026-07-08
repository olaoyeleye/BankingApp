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
  ami_type       = "AL2_x86_64"
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