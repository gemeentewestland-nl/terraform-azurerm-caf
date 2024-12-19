data "azurerm_subscription" "current" {
}

resource "azurerm_subscription_policy_assignment" "assignment" {
  name                 = var.name
  policy_definition_id = var.policy_definition_id
  subscription_id      = data.azurerm_subscription.current.id
  parameters           = jsonencode(local.parameters)
  identity {
    type = "SystemAssigned"
  }
  location = "west europe"
}

resource "azurerm_role_assignment" "assignment" {
  scope                = azurerm_subscription_policy_assignment.assignment.subscription_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_subscription_policy_assignment.assignment.identity[0].principal_id
}