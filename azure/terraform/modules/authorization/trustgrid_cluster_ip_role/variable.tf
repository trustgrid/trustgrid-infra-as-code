variable "name_prefix" {
    type        = string
    description = "Prefix for the resources created by this module"
  
}

variable "scope" {
    type        = string
    description = "Specifies the Azure Resource Manager (ARM) scope where the custom role definition itself is created or defined."
  
}

variable "assignable_scopes" {
    type        = list(string)
    description = "Defines the resources, resource groups, or subscriptions where the custom role can be used for assignments."
}