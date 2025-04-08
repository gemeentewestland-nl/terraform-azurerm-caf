variable "global_settings" {
  default = {}
}
variable "settings" {
  default = {}
}
variable "client_config" {
  description = "Client configuration object (see module README.md)."
}
variable "azuread_api_permissions" {
  default = {}
}
variable "user_type" {}

locals {
  # Extract the federated credentials map from the settings
  federated_credentials_map = lookup(var.settings, "federeded_credentials", {})

  # Convert the keys of the federated credentials map to a set of strings
  federated_credentials_set = federated_credentials_map != {} ? toset(keys(federated_credentials_map)) : toset([])
}