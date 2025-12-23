variable "region" {
  type        = string
  description = "region for bucket creation"
  default     = "us-east-1"
}


variable "environment" {
  type    = string
  default = "DEV"
}
variable "eks_version" {
  type    = string
  default = "1.33"
}

variable "cluster_name" {
  type    = string
  default = "amazon-eks-cluster"
}

variable "team" {
  type    = string
  default = "devops"
}

variable "private_subnets" {
  type    = list(string)
  default = []
}

variable "node_group_name" {
  type    = string
  default = "general"
}

variable "capacity_type" {
  type    = string
  default = "ON_DEMAND"
}

variable "worker_node_instance_types" {
  type    = list(string)
  default = ["t2.micro"]
}

variable "node_group_desired_size" {
  type    = number
  default = 1
}

variable "node_group_max_size" {
  type    = number
  default = 2
}

variable "node_group_min_size" {
  type    = number
  default = 1
}