locals {
  common_tags = {
    environment = var.environment
    managedBy   = var.team
    createdBy   = "terraform"
  }

  eks_version_tag = join("-", split(".", var.eks_version))

  applications_data = flatten([
    for domain_name, domain_data in var.applications : [
      for service_name in domain_data.services : {
        service = service_name
      }
    ]
  ])
}