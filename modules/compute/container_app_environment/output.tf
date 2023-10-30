output "id" {
  value = try(azurerm_container_app_environment.cae[0].id, azapi_resource.cae[0].id)
}
output "test" {
  value = try(jsondecode(azapi_resource.cae[0].output).properties, null)
}

output "default_domain" {
  value = try(azurerm_container_app_environment.cae[0].default_domain, jsondecode(azapi_resource.cae[0].output).properties.defaultDomain)
}

output "docker_bridge_cidr" {
  value = try(var.settings.infrastructure_subnet_id, null) != null ? try(azurerm_container_app_environment.cae[0].docker_bridge_cidr, jsondecode(azapi_resource.cae[0].output).properties.dockerBridgeCidr) : null
}

output "platform_reserved_cidr" {
  value = try(var.settings.infrastructure_subnet_id, null) != null ? try(azurerm_container_app_environment.cae[0].platform_reserved_cidr, jsondecode(azapi_resource.cae[0].output).properties.platformReservedCidr) : null
}

output "platform_reserved_dns_ip_address" {
  value = try(var.settings.infrastructure_subnet_id, null) != null ? try(azurerm_container_app_environment.cae[0].platform_reserved_dns_ip_address, jsondecode(azapi_resource.cae[0].output).properties.platformReservedDnsIP) : null
}

output "static_ip_address" {
  value = try(var.settings.internal_load_balancer_enabled, false) == true ? try(azurerm_container_app_environment.cae[0].static_ip_address, jsondecode(azapi_resource.cae[0].output).properties.staticIp) : null
}
