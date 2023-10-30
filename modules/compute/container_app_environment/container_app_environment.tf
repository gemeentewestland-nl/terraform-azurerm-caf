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
  count = can(var.settings.workload_profiles) ? 0 : 1
  name                           = azurecaf_name.cae.result
  location                       = local.location
  resource_group_name            = local.resource_group_name
  log_analytics_workspace_id     = can(var.settings.log_analytics_workspace_id) ? var.settings.log_analytics_workspace_id : var.diagnostics.log_analytics[var.settings.log_analytics_key].id

  infrastructure_subnet_id       = try(var.subnet_id, null)

  internal_load_balancer_enabled = try(var.settings.internal_load_balancer_enabled, false)
  tags                           = merge(local.tags, try(var.settings.tags, null))
}

data "azurerm_resource_group" "ca" {
  count = can(var.settings.workload_profiles) ? 1 : 0
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

resource "azapi_resource" "cae" {
  count     = can(var.settings.workload_profiles) ? 1 : 0
  type      = "Microsoft.App/managedEnvironments@2023-05-01"
  name      = azurecaf_name.cae.result
  parent_id = data.azurerm_resource_group.ca[0].id
  location  = local.location
  tags      = merge(local.tags, try(var.settings.tags, null))

  schema_validation_enabled = false
  ignore_missing_property = true
  ignore_casing = true

  response_export_values = ["*"]

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
        platformReservedCidr   = try(var.settings.platform_reserved_cidr, null)
        platformReservedDnsIP  = try(var.settings.platform_reserved_dns_ip, null)
      }: null
      workloadProfiles = local.workload_profiles
    }
  })
}