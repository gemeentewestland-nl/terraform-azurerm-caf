locals {
  secrets = flatten([
    for secret in try(var.settings.secrets, []) : [
      {
        name          = secret.name
        value         = try(secret.value, null)
        identity      = try(try(secret.managed_identity_id, var.combined_resources.managed_identities[try(secret.managed_identity.lz_key, var.client_config.landingzone_key)][try(secret.managed_identity_key, secret.managed_identity.key)].id), null)
        keyVaultUrl   = try(
          try(
            secret.keyvault_url, 
            format("%ssecrets/%s", var.combined_resources.keyvaults[try(secret.keyvault.lz_key, var.client_config.landingzone_key)][try(secret.keyvault_key, secret.keyvault.key)].vault_uri, try(var.dynamic_keyvault_secrets[try(secret.keyvault_key, secret.keyvault.key)][secret.dynamic_keyvault_secret_key].secret_name, try(secret.keyvault_secret_name, null)))
          )
        , null)
      }
    ] if can(secret.value) || can(try(secret.managed_identity_id, try(secret.managed_identity_key, secret.managed_identity.key)))
  ])

  managed_local_identities = flatten([
    for managed_identity_key in try(var.settings.identity.managed_identity_keys, []) : [
      var.combined_resources.managed_identities[var.client_config.landingzone_key][managed_identity_key].id
    ]
  ])

  managed_remote_identities = flatten([
    for lz_key, value in try(var.settings.identity.remote, []) : [
      for managed_identity_key in value.managed_identity_keys : [
        var.combined_resources.managed_identities[lz_key][managed_identity_key].id
      ]
    ]
  ])

  managed_identities = concat(local.managed_local_identities, local.managed_remote_identities)

  job_event_scale_rules = flatten([
    for rule in try(var.settings.job_event_scale_rules, []): [{
      name = rule.name
      type = rule.type
      metadata = rule.metadata
      auth = flatten([
        for auth in try(rule.authentication,[]): [{
          secretRef = auth.secret_name
          triggerParameter = auth.trigger_parameter
        }]
      ])
    }]
  ])
  
  containers = flatten([
    for key, container in var.settings.template.container: [{
      image   = container.image
      name    = try(container.name, "${key}")
      command = try(container.command, null)
      args    = try(container.args, null)
      env     = flatten([
        for env in try(container.env,[]):[{
          name      = env.name
          value     = try(tostring(env.value), null)
          secretRef = try(env.secret_name, null)
        }]
      ])
      probes = concat(
        flatten([
          for spk, startup_probe in try(container.startup_probe,[]): [{
            type                             = "Startup"
            failureThreshold                 = try(startup_probe.failure_count_threshold, null)
            httpGet = startup_probe.transport != "TCP" ? {
              httpHeaders = flatten([
                for hk, header in try(startup_probe.header, []): [{
                  name = header.name
                  value = header.value
                }]
              ])
              host                           = try(startup_probe.host, null)
              path                           = try(startup_probe.path, null)
              port                           = startup_probe.port
              scheme                         = startup_probe.transport
            }: null
            tcpSocket = startup_probe.transport == "TCP" ? {
              host                       = try(startup_probe.host, null)
              port                       = startup_probe.port
            }: null
            periodSeconds                    = try(startup_probe.interval_seconds, null)    
            timeoutSeconds                   = try(startup_probe.timeout, null)
            terminationGracePeriodSeconds	   = try(startup_probe.termination_grace_period_seconds, null)
          }]
        ]),
        flatten([
          for lpk, liveness_probe in try(container.liveness_probe,[]): [{
            type                             = "Liveness"
            failureThreshold                 = try(liveness_probe.failure_count_threshold, null)
            httpGet = liveness_probe.transport != "TCP" ? {
              httpHeaders = flatten([
                for hk, header in try(liveness_probe.header, []): [{
                  name = header.name
                  value = header.value
                }]
              ])
              host                           = try(liveness_probe.host, null)
              path                           = try(liveness_probe.path, null)     
              port                           = liveness_probe.port
              scheme                         = liveness_probe.transport
            }: null
            initialDelaySeconds = try(liveness_probe.initial_delay, null)
            tcpSocket = liveness_probe.transport == "TCP" ? {
              host                       = try(liveness_probe.host, null)
              port                       = liveness_probe.port
            }: null
            periodSeconds                    = try(liveness_probe.interval_seconds, null)    
            timeoutSeconds                   = try(liveness_probe.timeout, null)
            terminationGracePeriodSeconds	   = try(liveness_probe.termination_grace_period_seconds, null)
          }]
        ]),
        flatten([
          for rpk, readiness_probe in try(container.readiness_probe,[]): [{
            type                             = "Readiness"
            failureThreshold                 = try(readiness_probe.failure_count_threshold, null)
            httpGet = readiness_probe.transport != "TCP" ? {
              httpHeaders = flatten([
                for hk, header in try(readiness_probe.header, []): [{
                  name = header.name
                  value = header.value
                }] if readiness_probe.transport != "TCP"
              ])
              host                           = try(readiness_probe.host, null)
              path                           = try(readiness_probe.path, null)     
              port                           = readiness_probe.port
              scheme                         = readiness_probe.transport
            }: null
            successThreshold = try(readiness_probe.success_count_threshold, null)
            tcpSocket = readiness_probe.transport == "TCP" ? {
              host                       = try(readiness_probe.host, null)
              port                       = readiness_probe.port
            }: null
            periodSeconds                    = try(readiness_probe.interval_seconds, null)    
            timeoutSeconds                   = try(readiness_probe.timeout, null)
            terminationGracePeriodSeconds	   = try(readiness_probe.termination_grace_period_seconds, null)
          }]
        ])
      )
      resources = {
        cpu    = container.cpu
        memory = container.memory
      }
      volumeMounts = flatten([
        for vmk, volume_mount in try(container.volume_mounts,[]): [{
          mountPath  = volume_mount.path
          volumeName = volume_mount.name
          subPath    = try(volume_mount.sub_path, null)
        }]
      ])
    }]
  ])

  init_containers = flatten([
    for key, container in try(var.settings.template.init_containers, []): [{
      image   = container.image
      name    = try(container.name, "${key}")
      command = try(container.command, null)
      args    = try(container.args, null)
      env     = try(container.env, null)
      resources = {
        cpu    = container.cpu
        memory = container.memory
      }
      volumeMounts = flatten([
        for vmk, volume_mount in try(container.volume_mounts,[]): [{
          mountPath  = volume_mount.path
          volumeName = volume_mount.name
          subPath    = try(volume_mount.sub_path, null)
        }]
      ])
    }]
  ])

  volumes = flatten([
    for vk, volume in try(var.settings.template.volumes, []): [{
      mountOptions = try(volume.mount_options, null)
      name         = volume.name
      secrets      = try(volume.secrets, null)
      storageName  = try(volume.storage_name, null)
      storageType  = try(volume.storage_type, "EmptyDir")
    }]
  ])
}
