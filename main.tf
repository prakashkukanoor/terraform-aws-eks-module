locals {
  common_tags = {
    environment = var.environment
    managedBy   = var.team
    createdBy   = "terraform"
  }

  #   applications_data = flatten([
  #     for domain_name, domain_data in var.applications : [
  #       for bucket_name in domain_data.buckets : {
  #         team                      = domain_name
  #         policy_json_tpl_file_path = domain_data.s3_policy_json_tpl_path
  #         bucket_name               = bucket_name
  #         arn                       = domain_data.arn
  #       }
  #     ]
  #   ])
}

resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-${var.environment}-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_eks_cluster" "cluster" {
  name     = "${var.cluster_name}-${var.environment}-cluster"
  role_arn = aws_iam_role.cluster.arn
  version  = var.eks_version

  vpc_config {
    endpoint_private_access = false
    endpoint_public_access  = true

    subnet_ids = var.private_subnets
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]

}