resource "azurecaf_name" "ca" {
  name          = var.settings.name
  prefixes      = var.global_settings.prefixes
  resource_type = "azurerm_container_app"
  random_length = var.global_settings.random_length
  clean_input   = true
  passthrough   = var.global_settings.passthrough
  use_slug      = var.global_settings.use_slug
}

data "azurerm_resource_group" "ca" {
  name = local.resource_group_name
}

resource "azapi_resource" "container_app_job" {
  type      = "Microsoft.App/jobs@2023-05-02-preview"
  name      = azurecaf_name.ca.result
  location  = data.azurerm_resource_group.ca.location 
  parent_id = data.azurerm_resource_group.ca.id
  tags = merge(local.tags, try(var.settings.tags, {}))

  dynamic "identity" {
    for_each = can(var.settings.identity) ? [1] :[] 
    
    content {
      type         = var.settings.identity.type
      identity_ids = local.managed_identities
    }
  }

  # Need to set to false because at the moment only 2022-11-01-preview is supported
  schema_validation_enabled = false
  ignore_missing_property = true
  ignore_casing = true

  body = jsonencode({
    properties = {
      
      environmentId       = var.container_app_environment_id
      workloadProfileName = try(var.settings.workload_profile_name, "Consumption")
      configuration = {
        dapr                  = can(var.settings.dapr) ? {
          appId = var.settings.dapr.id
          appPort = try(var.settings.dapr.port, null)
          appProtocol = try(var.settings.dapr.protocol, null)
          enableApiLogging = try(var.settings.dapr.enable_api_logging, null)
          enabled = try(var.settings.dapr.enabled, null)
          httpMaxRequestSize = try(var.settings.dapr.http_max_request_size, null)
          httpReadBufferSize = try(var.settings.dapr.http_read_buffer_size, null)
          logLevel = try(var.settings.dapr.log_level, null)
        } :null 

        secrets               = try(local.secrets, null)
        triggerType           = var.settings.trigger_type
        replicaTimeout        = try(var.settings.replica_timeout, 10800) # 3 hours
        replicaRetryLimit     = try(var.settings.replica_retry_limit, 1)
        manualTriggerConfig   = var.settings.trigger_type == "Manual" ? {
          parallelism            = try(var.settings.parallelism, 1)
          replicaCompletionCount = try(var.settings.replica_completion_count, 1)
        }:null
        eventTriggerConfig    = var.settings.trigger_type == "Event" ? {
          replicaCompletionCount = try(var.settings.replica_completion_count, 1)
          parallelism            = try(var.settings.parallelism, 1)
          scale = {
            minExecutions   = try(var.settings.scale_min_executions, 0)
            maxExecutions   = try(var.settings.scale_max_executions, 10)
            pollingInterval = try(var.settings.scale_polling_interval, 30)
            rules           = local.job_event_scale_rules
          }
        }: null
        scheduleTriggerConfig = var.settings.trigger_type == "Schedule" ? {
          cronExpression         = var.settings.cron_expression
          replicaCompletionCount = try(var.settings.replica_completion_count, 1)
          parallelism            = try(var.settings.parallelism, 1)
        }:null
        
        registries = can(var.settings.registry) ? [
          {
            server = var.settings.registry.server
            identity = try(var.settings.registry.identity, null)
            passwordSecretRef = try(var.settings.registry.password_secret_name, null)    
            username = try(var.settings.registry.username, null)
          } 
        ] : []    
      }
      template = {
        containers = local.containers
        initContainers = can(var.settings.template.init_containers) ? local.init_containers : null
        volumes        = can(var.settings.template.volumes) ? local.volumes : null
      }
    }
  })
}