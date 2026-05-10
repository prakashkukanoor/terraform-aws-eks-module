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