variable "cluster_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "team" {
  type = string
}

variable "applications" {
  type = map(object({
    services = list(string)
  }))
}

variable "eks_version" {
  type = string
}

variable "eks_private_subnets" {
  type = list(string)
}

variable "instance_type" {
  type = string
}

variable "eks_worker_node_desired_capacity" {
  type = number
}

variable "eks_worker_node_min_size" {
  type = number
}

variable "eks_worker_node_max_size" {
  type = number
}

variable "endpoint_private_access" {
  type    = bool
  default = true
}

variable "endpoint_public_access" {
  type    = bool
  default = false
}

variable "console_user_arn" {
  type = string
}

variable "ami_type" {
  type = string
}