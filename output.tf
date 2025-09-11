output "cluster_arn" {
  value = aws_eks_cluster.cluster.arn
}

output "cluster_endpoint" {
  value = aws_eks_cluster.cluster.endpoint
}