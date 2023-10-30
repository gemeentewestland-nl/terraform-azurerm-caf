resource "azurecaf_name" "cae" {
  name          = var.settings.name
  resource_type = "azurerm_container_app_environment"
  prefixes      = var.global_settings.prefixes
  random_length = var.global_settings.random_length
  clean_input   = true
  passthrough   = var.global_settings.passthrough
  use_slug      = var.global_settings.use_slug
}

resource "azurerm_container_app_environment" "cae" {
  count = can(settings.workload_profiles) ? 0 : 1
  name                           = azurecaf_name.cae.result
  location                       = local.location
  resource_group_name            = local.resource_group_name
  log_analytics_workspace_id     = can(var.settings.log_analytics_workspace_id) ? var.settings.log_analytics_workspace_id : var.diagnostics.log_analytics[var.settings.log_analytics_key].id
  
  infrastructure_subnet_id       = try(var.subnet_id, null)
  zone_redundancy_enabled        = try(var.settings.zone_redundancy_enabled, null)

  internal_load_balancer_enabled = try(var.settings.internal_load_balancer_enabled, false)
  platform_reserved_cidr         = try(var.settings.platform_reserved_cidr)
  docker_bridge_cidr               = try(var.settings.docker_bridge_cidr, null)
  tags                           = merge(local.tags, try(var.settings.tags, null))
}

data "azurerm_resource_group" "ca" {
  count = can(settings.workload_profiles) ? 1 : 0
  name = local.resource_group_name
}

locals {
  workload_profiles = flatten([
    for wpk, workload_profile in try(var.settings.workload_profiles,[]): [{
      maximumCount        = try(workload_profile.max_count, null)
      minimumCount        = try(workload_profile.min_count, null)
      name                = workload_profile.name
      workloadProfileType = try(workload_profile.type, "Consumption")
    }]
  ])
}

resource "azapi_resource" "container_app_environment" {
  count = can(settings.workload_profiles) ? 1 : 0
  type      = "Microsoft.App/managedEnvironments@2023-05-01"
  name      = azurecaf_name.cae.result
  parent_id = data.azurerm_resource_group.ca.id
  location  = local.location
  tags      = merge(local.tags, try(var.settings.tags, null))

  body = jsonencode({
    properties = {
      appLogsConfiguration = can(var.settings.log_analytics_workspace_id) ? {  
        destination = "log-analytics"
        logAnalyticsConfiguration = {
          customerId = can(var.settings.log_analytics_workspace_id) ? var.settings.log_analytics_workspace_id : var.diagnostics.log_analytics[var.settings.log_analytics_key].id
          sharedKey  = can(var.settings.log_analytics_workspace_id) ? var.settings.log_analytics_primary_shared_key : var.diagnostics.log_analytics[var.settings.log_analytics_key].primary_shared_key
        }
      }: null
      vnetConfiguration = can(var.subnet_id)? {
        dockerBridgeCidr       = try(var.settings.docker_bridge_cidr, null)
        infrastructureSubnetId = try(var.subnet_id, null)
        internal               = try(var.settings.internal_load_balancer_enabled, false)
        platformReservedCidr   = try(var.settings.platform_reserved_cidr)
        platformReservedDnsIP  = try(var.settings.platform_reserved_dns_ip, null)
      }: null
      workloadProfiles = var.settings.workload_profiles
    }
  })
}