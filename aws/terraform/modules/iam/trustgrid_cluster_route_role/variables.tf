variable "name_prefix" {
    type = string
    description = "Name prefix for the role and related resources"
    default = "trustgrid-cluster-route"  
}

variable "route_table_ids" {
    type = list(string)
    description = "List of route table IDs the role will be allowed to manage"  
}
