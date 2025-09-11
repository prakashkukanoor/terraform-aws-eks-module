locals {
  common_tags = {
    environment = var.environment
    managedBy   = var.team
    createdBy   = "terraform"
  }
  cluster_name = "${var.cluster_name}-${var.environment}"

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
  name = "${local.cluster_name}-eks-cluster-role"
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

resource "aws_iam_role" "node" {
  name = "${local.cluster_name}-eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole"]
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "amazon_eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_eks_cluster" "cluster" {
  name     = "${local.cluster_name}-cluster"
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

  tags = merge(
    local.common_tags,
  { Name = "eks-${var.eks_version}-${var.environment}" })

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]

}

data "aws_ami" "eks_nodes" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [var.filter_name]
  }
}

resource "aws_launch_template" "eks_nodes" {
  image_id      = data.aws_ami.eks_nodes.id
  instance_type = var.instance_type

  tag_specifications {
    resource_type = "instance"
    tags = merge(
    local.common_tags,
  { Name = "eks-node-${var.eks_version}-${var.environment}" })
  }
}


resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnets

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

#   capacity_type  = var.capacity_type
#   instance_types = var.worker_node_instance_types

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = "$Latest"
  }
  
  update_config {
    max_unavailable = 1
  }

  tags = merge(
    local.common_tags,
  { Name = "eks-node-${var.eks_version}-${var.environment}" })

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}