variable "global_settings" {
  default = {}
}
variable "settings" {
  default = {
    federeded_credentials = {}
  }
}
variable "client_config" {
  description = "Client configuration object (see module README.md)."
}
variable "azuread_api_permissions" {
  default = {}
}
variable "user_type" {}
