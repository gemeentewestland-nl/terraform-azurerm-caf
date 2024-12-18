module "policies_assignment" {
  source   = "./modules/policies/assignment"
  for_each = local.policies.policy_assignment

  name                     = each.value.name
  policy_definition_id     = each.value.policy_definition_id
  parameters               = each.value.parameters
}

output "policies_assignment" {
  value = module.policies_assignment
}




