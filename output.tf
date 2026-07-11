output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.this.name
}

output "cluster_security_group_id" {
  description = "EKS cluster Security group ID"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "cluster_iam_role_name" {
  description = "EKS cluster IAM role"
  value       = aws_iam_role.cluster_role.name
}

# output "cluster_certificate_authority_data" {
#   description = "Base64 encoded certificate data required to communicate with the cluster"
#   value       = aws_eks_cluster.this.certificate_authority[0].data
# }

output "node_group_name" {
  description = "EKS node group"
  value       = aws_autoscaling_group.eks_nodes.name
}

output "aws_autoscaling_group_id" {
  description = "EKS node group Name"
  value       = aws_autoscaling_group.eks_nodes.id
}

output "configure_kubectl" {
  description = "Command to configure kubectl to connect to EKS"
  value       = "aws eks update-kubeconfig --region <region> --name ${local.cluster_full_name} --profile ${var.environment}"
}