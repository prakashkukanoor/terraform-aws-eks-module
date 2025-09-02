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
  default = "1.31"
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