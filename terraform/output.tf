output "eks_cluster_name" {
  value       = aws_eks_cluster.main.name
  description = "EKS cluster name"
}


output "eks_cluster_endpoint" {
  value       = aws_eks_cluster.main.endpoint
  description = "EKS cluster endpoint"
}

output "nginx_public_ip" {
  value       = aws_instance.nginx.public_ip
  description = "Public IP of Nginx server"
}