data "aws_ssm_parameter" "eks_ami" {
  name = "/aws/service/eks/optimized-ami/${aws_eks_cluster.this.version}/amazon-linux-2023/x86_64/standard/recommended/image_id"
}

resource "aws_launch_template" "eks_nodes" {
  name                   = "${var.cluster_name}-eks${local.eks_version_tag}-node-template"
  instance_type          = var.instance_type
  image_id               = data.aws_ssm_parameter.eks_ami.value
  vpc_security_group_ids = [aws_eks_cluster.this.vpc_config[0].cluster_security_group_id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -o xtrace
    /etc/eks/bootstrap.sh ${var.cluster_name}
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(
    local.common_tags,
    {Name = "${var.cluster_name}-eks${local.eks_version_tag}-node-${var.environment}"}
    )
  }
}

resource "aws_autoscaling_group" "eks_nodes" {
  name                = "${var.cluster_name}-${var.eks_version}-node-asg-${var.environment}"
  desired_capacity    = var.eks_worker_node_desired_capacity
  max_size            = var.eks_worker_node_max_size
  min_size            = var.eks_worker_node_min_size
  target_group_arns   = []
  vpc_zone_identifier = var.eks_private_subnets

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = "$Latest"
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }
}