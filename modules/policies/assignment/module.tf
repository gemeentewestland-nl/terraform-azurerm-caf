data "azurerm_subscription" "current" {
}

resource "azurerm_subscription_policy_assignment" "assignment" {
  name                 = var.name
  policy_definition_id = var.policy_definition_id
  subscription_id      = data.azurerm_subscription.current.id
  parameters           = local.parameters
}
