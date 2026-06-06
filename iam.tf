resource "aws_iam_role" "cluster_role" {
  name = "${local.cluster_full_name}-role"
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
  role       = aws_iam_role.cluster_role.name
}

resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# resource "aws_eks_access_entry" "std" {
#   for_each = {for iam in var.eks_iam_access: iam.user_arn => iam.role}

#   cluster_name  = aws_eks_cluster.this.name
#   principal_arn = each.key                      # The role attached to your EC2s
#   type          = "STANDARD"                    # This is the "magic" switch for self-managed nodes
#   tags = merge(
#     local.common_tags,
#   { Name = local.cluster_full_name })
# }

# # 2. Grant yourself Cluster Admin permissions
# resource "aws_eks_access_policy_association" "std" {
#   for_each = {for iam in var.eks_iam_access: iam.user_arn => iam.role}

#   cluster_name  = aws_eks_cluster.this.name
#   policy_arn    = local.user_role_policy_map[each.value]
#   principal_arn = each.key

#   access_scope {
#     type = "cluster"
#   }
# }

resource "aws_eks_access_entry" "console_admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.console_user # The role attached to your EC2s
  type          = "STANDARD"                    # This is the "magic" switch for self-managed nodes
}

# 2. Grant yourself Cluster Admin permissions
resource "aws_eks_access_policy_association" "console_admin" {
  cluster_name  = aws_eks_cluster.this.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.console_user

  access_scope {
    type = "cluster"
  }
}