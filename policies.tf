module "policies_assignment" {
  source   = "./modules/policies/assignment"
  for_each = local.policies.policy_assignment

  name                     = each.value.name
}

output "policies_assignment" {
  value = module.policies_assignment
}




