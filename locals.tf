locals {
  common_tags = {
    environment = var.environment
    managedBy   = var.team
    createdBy   = "terraform"
  }

  eks_version_tag   = join("-", split(".", var.eks_version))
  cluster_full_name = "${var.cluster_name}-eks${local.eks_version_tag}-${var.environment}"

  cluster_asg_tags = {
    "kubernetes.io/cluster/${local.cluster_full_name}"     = "owned"
    "k8s.io/cluster-autoscaler/${local.cluster_full_name}" = "owned"
    "k8s.io/cluster-autoscaler/enabled"                    = "true"
    "Environment"                                          = var.environment
  }

  applications_data = flatten([
    for domain_name, domain_data in var.applications : [
      for service_name in domain_data.services : {
        service = service_name
      }
    ]
  ])

eks_user_access = flatten([
    for eks_role, iam_user_list in var.eks_iam_user_access : [
      for iam_user in iam_user_list : {
        user = iam_user
        role = eks_role
      }
    ]
  ])

  iam_user_arn_format = "arn:aws:iam::${var.aws_account_number}:user/"

  user_role_policy_map = {
    admin  = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    editor = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
    viewer = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
  }
}