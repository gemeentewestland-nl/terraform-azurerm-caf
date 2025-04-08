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
  # Extract the values from the object and convert them to a set of strings
  federated_credentials = lookup(var.settings, "federeded_credentials", {}) != {} ? toset(keys(lookup(var.settings, "federeded_credentials", {}))) : toset([])
}