output "eks_cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = aws_eks_cluster.cluster.arn
}


output "sg_eks_nodes_allow_nlb" {
  value = aws_security_group.eks_nodes_allow_nlb.id
}