variable "name" {
}

variable "policy_definition_id" {
}

variable "parameters" {
}

locals {
    parameters = { 
    for param in var.parameters : param.key => { 
      value = param.value 
    }
  }
}