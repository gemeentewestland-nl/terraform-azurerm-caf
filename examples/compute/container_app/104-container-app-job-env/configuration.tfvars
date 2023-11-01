global_settings = {
  default_region = "region1"
  regions = {
    region1 = "westeurope"
  }
}

resource_groups = {
  rg1 = {
    name   = "container-app-001"
    region = "region1"
  }
}

diagnostic_log_analytics = {
  central_logs_region1 = {
    region             = "region1"
    name               = "logs"
    resource_group_key = "rg1"
  }
}

vnets = {
  cae_re1 = {
    resource_group_key = "rg1"
    region             = "region1"
    vnet = {
      name          = "container-app-network"
      address_space = ["100.64.0.0/24"]
    }
    specialsubnets = {}
    subnets = {
      cae1 = {
        name    = "container-app-snet"
        cidr    = ["100.64.0.0/26"]
        nsg_key = "empty_nsg"
        delegation = {
          name               = "containerapps"
          service_delegation = "Microsoft.App/environments"
          actions = [
            "Microsoft.Network/virtualNetworks/subnets/join/action"
          ]
        }
      }
    }
  }
}

network_security_group_definition = {
  # This entry is applied to all subnets with no NSG defined
  empty_nsg = {}
}

keyvaults = {
  secrets = {
    name               = "secrets"
    resource_group_key = "rg1"
    sku_name           = "standard"

    enabled_for_deployment = true

    creation_policies = {
      logged_in_user = {
        certificate_permissions = ["Get", "List", "Update", "Create", "Import", "Delete", "Purge", "Recover"]
        secret_permissions      = ["Set", "Get", "List", "Delete", "Purge", "Recover"]
      }
      msi1 = {
        managed_identity_key = "msi1"
        secret_permissions   = ["Get"]
      }
    }
  }
}

dynamic_keyvault_secrets = {
  secrets = { # Key of the keyvault
    github_personal_access_token = {
      secret_name = "PersonalAccessToken"
      value       = "" # Update with your own PAT in azure
    }
  }
}

managed_identities = {
  msi1 = {
    name               = "ca-identity-001"
    resource_group_key = "rg1"
  }
}

container_app_environment = {
  cae1 = {
    name                           = "cont-app-env-001"
    region                         = "region1"
    resource_group_key             = "rg1"
    log_analytics_key              = "central_logs_region1"
    vnet = {
      vnet_key   = "cae_re1"
      subnet_key = "cae1"
    }
    internal_load_balancer_enabled = true

    workload_profiles = {   
      # runners_d4 = {
      #   name                = "runners"
      #   type                 = "D4"
      #   minimumCount        = 0
      #   maximumCount        = 3
      # }
      consumption = {
        name  = "consumption"
        type  = "Consumption"
      }
    }

    tags = {
      environment = "testing"
    }
  }
}

container_app_job = {
  ca1 = {
    name                          = "github_runner"
    container_app_environment_key = "cae1"
    resource_group_key            = "rg1"
    
    trigger_type                  = "Event" # Event, Manual or Schedule
    scale_min_executions          = 0
    scale_max_executions          = 2
    job_event_scale_rules = {
      github_runner = {
        name = "github-runner"
        type = "github-runner" # https://keda.sh/docs/2.11/scalers/github-runner/
        metadata = {
          # Optional: The URL of the GitHub API, defaults to https://api.github.com
          githubAPIURL = "https://api.github.com"
          #githubAPIURLFromEnv = ""
          # Required: The owner of the GitHub repository, or the organization that owns the repository
          owner = "gemeentewestland-nl"
          #ownerFromEnv = "GH_OWNER"
          # Required: The scope of the runner, can be either "org" (organisation), "ent" (enterprise) or "repo" (repository)
          runnerScope = "repo"
          #runnerScopeFromEnv = ""
          # Optional: The list of repositories to scale, separated by comma
          repos = "westland-cloud-platform"
          #reposFromEnv = "GH_REPOSITORY"
          # Optional: The list of runner labels to scale on, separated by comma
          labels = "platform"
          #labelsFromEnv = "RUNNER_LABELS"
          # Optional: The target number of queued jobs to scale on
          targetWorkflowQueueLength = "1" # Default 1
          # targetWorkflowQueueLengthFromEnv = ""
          # Optional: The name of the application ID from the GitHub App
          #applicationID             =  "{applicatonID}"
          #applicationIDFromEnv = ""
          # Optional: The name of the installation ID from the GitHub App once installed into Org or repo.
          #installationID.           = "{installationID}"
          #installationIDFromEnv
        }
        auth = {
          pat_token = {
            secret_name       = "pat-token-secret"
            trigger_parameter = "personalAccessToken" # The Personal Access Token (PAT) for GitHub from your user. (Optional, Required if GitHub App not used)
            #trigger_parameter = "appKey"              # The private key for the GitHub App. This is the contents of the .pem file you downloaded when you created the GitHub App. (Optional, Required if applicationID set)
          }
        }
      }
    }
  
    revision_mode = "Single"
    template = {
      container = {
        cont1 = {
          name   = "github-runner-container"
          image  = "aztfmod/rover-agent:1.5.7-2310.0211-github"
          cpu    = 2.0
          memory = "4Gi"
          
          env = [
            {
              # Runner labels. 
              name  = "RUNNER_LABELS"
              value = "platform"
            },
            {
              name  = "EPHEMERAL"
              value = "true"
            },
            {
              name  = "URL"
              value = "https://github.com"
            },
            # Connect to GitHub using GH_TOKEN, GH_OWNER and GH_REPOSITORY  environment variables to retrieve registration token. Do NOT use AGENT_TOKEN env in this case
            {
              name        = "GH_TOKEN"
              secret_name = "pat-token-secret" # Use NOT use in case of enterprise runner
            },
            {
              name  = "GH_OWNER"
              value = "gemeentewestland-nl"
            },
            {
              name  = "GH_REPOSITORY"
              value = "westland-cloud-platform" # Hack to supply runnergroup
            }
          ]
        }
      }
      min_replicas = 1
      max_replicas = 2
    }

    secrets = [
      {
        name                        = "pat-token-secret"
        managed_identity_key        = "msi1"
        keyvault_key                = "secrets"
        dynamic_keyvault_secret_key = "github_personal_access_token"
      }
    ]
      
    identity = {
      type = "UserAssigned" // Possible options are 'SystemAssigned, UserAssigned' 'SystemAssigned' or 'UserAssigned'
      managed_identity_keys = [
        "msi1"
      ]
    }
  }
}
