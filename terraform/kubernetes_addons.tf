resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_role.arn

  # Do not pin addon_version: EKS uses its default on create, and on import
  # the deployed version is adopted. This avoids version-drift reconciliation loops.
  preserve                    = true
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  # Avoid churn-driven re-updates that collide with in-flight AWS updates.
  # After creation/import, Terraform treats these fields as immutable.
  lifecycle {
    ignore_changes = [
      service_account_role_arn,
      addon_version,
    ]
  }

  timeouts {
    create = "20m"
    update = "20m"
    delete = "20m"
  }

  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi_policy,
    aws_eks_node_group.main
  ]
}