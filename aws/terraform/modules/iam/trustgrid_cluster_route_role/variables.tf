variable "name_prefix" {
    type = string
    description = "Name prefix for the role and related resources"
    default = "trustgrid-cluster-route"  
}

variable "route_table_arns" {
    type = list(string)
    description = "List of route table ARNs the role will be allowed to manage"  
}