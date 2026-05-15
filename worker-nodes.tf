data "aws_ssm_parameter" "eks_ami" {
  name = "/aws/service/eks/optimized-ami/${aws_eks_cluster.this.version}/amazon-linux-2023/x86_64/standard/recommended/image_id"
}

resource "aws_launch_template" "eks_nodes" {
  name                   = "${local.cluster_full_name}-node-template"
  instance_type          = var.instance_type
  image_id               = data.aws_ssm_parameter.eks_ami.value
  vpc_security_group_ids = [aws_eks_cluster.this.vpc_config[0].cluster_security_group_id]

  user_data = base64encode(<<-EOT
    ---
    apiVersion: node.eks.aws/v1alpha1
    kind: NodeConfig
    spec:
      cluster:
        name: ${local.cluster_full_name}
        apiServerEndpoint: ${aws_eks_cluster.this.endpoint}
        certificateAuthority: ${aws_eks_cluster.this.certificate_authority[0].data}
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