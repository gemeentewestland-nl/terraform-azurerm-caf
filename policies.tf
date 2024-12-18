module "policies_assignment" {
  source   = "./modules/policies/assignment"
  for_each = local.policies.policy_assignment

  name                     = each.value.name
}

output "maintenance_configuration" {
  value = module.policies_assignment
}




