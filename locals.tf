locals {
  common_tags = {
    environment = var.environment
    managedBy   = var.team
    createdBy   = "terraform"
  }

  applications_data = flatten([
    for domain_name, domain_data in var.applications : [
      for service_name in domain_data.services : {
        service = service_name
      }
    ]
  ])
}