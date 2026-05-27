data "aws_ssm_parameter" "eks_ami" {
  name = "/aws/service/eks/optimized-ami/${aws_eks_cluster.this.version}/${var.ami_type}/recommended/image_id"
}

resource "aws_launch_template" "eks_nodes" {
  name                   = "${local.cluster_full_name}-node-template"
  instance_type          = var.instance_type
  image_id               = data.aws_ssm_parameter.eks_ami.value
  vpc_security_group_ids = [aws_eks_cluster.this.vpc_config[0].cluster_security_group_id]

  iam_instance_profile {
    name = aws_iam_instance_profile.eks_node_profile.name
  }

  user_data = base64encode(<<-EOT
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="BOUNDARY"

--BOUNDARY
Content-Type: application/node.eks.aws

---
apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  cluster:
    name: ${local.cluster_full_name}
    apiServerEndpoint: ${aws_eks_cluster.this.endpoint}
    certificateAuthority: ${aws_eks_cluster.this.certificate_authority[0].data}
    cidr: ${aws_eks_cluster.this.kubernetes_network_config[0].service_ipv4_cidr}

--BOUNDARY--
EOT
)



  tag_specifications {
    resource_type = "instance"
    tags = merge(
      local.common_tags,
      { Name = "${local.cluster_full_name}-node" }
    )
  }
}

resource "aws_autoscaling_group" "eks_nodes" {
  name                = "${local.cluster_full_name}-node-asg"
  desired_capacity    = var.eks_worker_node_desired_capacity
  max_size            = var.eks_worker_node_max_size
  min_size            = var.eks_worker_node_min_size
  target_group_arns   = []
  vpc_zone_identifier = var.eks_private_subnets

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = local.cluster_asg_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_eks_access_entry" "this" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_iam_role.eks_node_role.arn # The role attached to your EC2s
  type          = "EC2_LINUX"                    # This is the "magic" switch for self-managed nodes
}

resource "aws_iam_instance_profile" "eks_node_profile" {
  name = "${local.cluster_full_name}-node-profile"
  role = aws_iam_role.eks_node_role.name # Matches the role in your access entry
}

resource "aws_eks_access_entry" "console_admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.console_user_arn # The role attached to your EC2s
  type          = "STANDARD"                    # This is the "magic" switch for self-managed nodes
}

# 2. Grant yourself Cluster Admin permissions
resource "aws_eks_access_policy_association" "console_admin" {
  cluster_name  = aws_eks_cluster.this.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.console_user_arn

  access_scope {
    type = "cluster"
  }
}
