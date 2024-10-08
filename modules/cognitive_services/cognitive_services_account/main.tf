terraform {
  required_providers {
    azurecaf = {
      source = "aztfmod/azurecaf"
    }
  }
}

locals {
  location = coalesce(var.location, var.resource_group.location)
  tags = var.base_tags ? merge(
    var.global_settings.tags,
    try(var.resource_group.tags, null),
    try(var.settings.tags, null)
  ) : try(var.settings.tags, null)
}
