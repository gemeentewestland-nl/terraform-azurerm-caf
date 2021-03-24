module "caf" {
  source = "../../../../../"

  global_settings    = var.global_settings
  resource_groups    = var.resource_groups
  storage_accounts   = var.storage_accounts
  keyvaults          = var.keyvaults
  managed_identities = var.managed_identities
  role_mapping       = var.role_mapping

  diagnostics = {
    # Get the diagnostics settings of services to create
    diagnostic_storage_accounts = var.diagnostic_storage_accounts
  }


  compute = {
    virtual_machines = var.virtual_machines
  }

  networking = {
    application_security_groups           = var.application_security_groups
    network_security_group_definition     = var.network_security_group_definition
    networking_interface_asg_associations = var.networking_interface_asg_associations
    public_ip_addresses                   = var.public_ip_addresses
    vnets                                 = var.vnets
   
  }
}
