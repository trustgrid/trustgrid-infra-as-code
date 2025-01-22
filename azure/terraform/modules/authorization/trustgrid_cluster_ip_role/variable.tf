variable "name_prefix" {
    type        = string
    description = "Prefix for the resources created by this module"
  
}

variable "assignable_scopes" {
    type        = list(string)
    description = "Scope to limit where the role can be assigned. This can be a subscription, resource group, or resource ID."
}