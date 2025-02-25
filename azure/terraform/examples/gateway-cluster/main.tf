terraform {
    required_providers {
      azurerm = {
        source = "hashicorp/azurerm"
        version = "~> 4.15.0"
      }
      tg = { 
        ## Remove if you are not using the Trustgrid provider to generate  the TrustGrid license
        source = "trustgrid/tg"
        version = "~> 1.10.3"
      }
      cloudinit = {
        source = "hashicorp/cloudinit"
        version = "~> 2.3.5"
      }
    }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

provider "tg" {
  ## Remove if you are not using the Trustgrid provider to generate  the TrustGrid license
  api_host = var.tg_api_host
}

provider "cloudinit" {  
}

## Example Resource Group and Virtual Network creation. If using 
resource "azurerm_resource_group" "trustgrid" {
  name     = "${var.environment_prefix}-trustgrid-rg"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.environment_prefix}-vnet"
  location            = azurerm_resource_group.trustgrid.location
  resource_group_name = azurerm_resource_group.trustgrid.name
  address_space       = [var.vnet_cidr]

  tags = {
    Environment = var.environment_prefix
  }
}

resource "azurerm_subnet" "public" {
  name                 = "${var.environment_prefix}-public"
  resource_group_name  = azurerm_resource_group.trustgrid.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.public_cidr]
}

resource "azurerm_subnet" "private" {
  name                 = "${var.environment_prefix}-private"
  resource_group_name  = azurerm_resource_group.trustgrid.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.private_cidr]
}

resource "azurerm_network_security_group" "public" {
  name                = "${var.environment_prefix}-public-nsg"
  location            = azurerm_resource_group.trustgrid.location
  resource_group_name = azurerm_resource_group.trustgrid.name
}

resource "azurerm_network_security_group" "private" {
  name                = "${var.environment_prefix}-private-nsg"
  location            = azurerm_resource_group.trustgrid.location
  resource_group_name = azurerm_resource_group.trustgrid.name
}

## Configure Security Group Rules for Trustgrid Gateways. These rules are required for the Trustgrid Gateways to function. The module can also optionally create rules for the Gateways to act as Wireguard or ZTNA Application gateways.  

module "trustgrid_gateway_security_group_rules" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//azure/terraform/modules/network/trustgrid_gateway_security_group_rules?ref=v0.2.0"

  name_prefix                          = var.environment_prefix
  security_group_id                    = resource.azurerm_network_security_group.public.id
  security_group_rule_priority_start   = 200
  
  trustgrid_data_plane_gateway_tcp     = true  ## True is the default value so this line could be omitted
  trustgrid_data_plane_gateway_tcp_port = "8443" ## 8443 is the default value so this line could be omitted
  trustgrid_data_plane_gateway_udp     = true  ## True is the default value so this line could be omitted
  trustgrid_data_plane_gateway_udp_port = "8443" ## 8443 is the default value so this line could be omitted
}

## Create Trustgrid Gateways
### The below example shows creating one gateway with the manual registration module and the other with the automatic registration module. A real deployment should use the same module for both gateways depending on the desired registration method.
module "az_gw1" {
    source = "github.com/trustgrid/trustgrid-infra-as-code//azure/terraform/modules/compute/trustgrid_single_node_manual_reg?ref=v0.2.0"
    resource_group_name = azurerm_resource_group.trustgrid.name
    location = azurerm_resource_group.trustgrid.location

    name = "${var.environment_prefix}-${var.az_gw1_name}"
    availability_zone = var.az_gw1_zone
    admin_ssh_key_pub = var.admin_ssh_key_pub
    
    public_subnet_id = azurerm_subnet.public.id
    public_security_group_id = azurerm_network_security_group.public.id
    private_subnet_id = azurerm_subnet.private.id
    private_security_group_id = azurerm_network_security_group.private.id
    

}


### The below example uses the Trustgrid provider to generate the license for the gateway. Then uses the auto registration module to create the VM and have it register with the Trustgrid control plane automatically.
resource "tg_license" "az_gw2" {
    name = "${var.environment_prefix}-${var.az_gw2_name}"
}

module "az_gw2" {
    source = "github.com/trustgrid/trustgrid-infra-as-code//azure/terraform/modules/compute/trustgrid_single_node_auto_reg?ref=v0.2.0"
    resource_group_name = azurerm_resource_group.trustgrid.name
    location = azurerm_resource_group.trustgrid.location

    name = "${var.environment_prefix}-${var.az_gw2_name}"
    availability_zone = var.az_gw2_zone
    admin_ssh_key_pub = var.admin_ssh_key_pub
    
    public_subnet_id = azurerm_subnet.public.id
    public_security_group_id = azurerm_network_security_group.public.id
    private_subnet_id = azurerm_subnet.private.id
    private_security_group_id = azurerm_network_security_group.private.id

    tg_license = tg_license.az_gw2.license
  
}

## Use TG Provider to confirm registration and get UID. This is not required but if you plan to use the TG provider to configure the gateway, you will need the UID.
data "tg_node" "az_gw2" {
    fqdn = tg_license.az_gw2.fqdn
    timeout = 300 # Time in seconds to wait for registration. 
    depends_on = [ module.az_gw2 ]
}

## Assign GWs to Application Security Group
resource "azurerm_network_interface_application_security_group_association" "az_gw1" {
  network_interface_id = module.az_gw1.public_nic_id
  application_security_group_id = module.trustgrid_gateway_security_group_rules.application_security_group_id
}

resource "azurerm_network_interface_application_security_group_association" "az_gw2" {
  network_interface_id = module.az_gw2.public_nic_id
  application_security_group_id = module.trustgrid_gateway_security_group_rules.application_security_group_id
}
## Explicitly Allow Traffic to the Trustgrid Control Plane 
## This would only be required if the security group does not allow all outbound traffic to the Internet

module "trustgrid_outbound_cp_rules" {
  source = "github.com/trustgrid/trustgrid-infra-as-code//azure/terraform/modules/network/trustgrid_outbound_control_plane_security_group_rules?ref=v0.2.0"
  name_prefix = var.environment_prefix
  security_group_id = azurerm_network_security_group.public.id
  security_group_rule_priority_start = 300
} 

## Below shows how to create Azure IAM Roles for managing Cluster High Availability with both the floating Cluster IP method and by managing route tables.  Typically you'd only use one of these methods.

## Create Roles Required for Cluster IP and Assign to the Trustgrid Gateways
data "azurerm_subscription" "current" {
}



module "trustgrid_cluster_ip_role" {
    source = "github.com/trustgrid/trustgrid-infra-as-code//azure/terraform/modules/authorization/trustgrid_cluster_ip_role?ref=v0.2.0"
    name_prefix = var.environment_prefix
    scope = data.azurerm_subscription.current.id
    assignable_scopes = [ data.azurerm_subscription.current.id ]
  
}

resource "azurerm_role_assignment" "az_gw1_cluster_ip" {
    scope = azurerm_resource_group.trustgrid.id
    role_definition_name = module.trustgrid_cluster_ip_role.name
    principal_id = module.az_gw1.principal_id
}

resource "azurerm_role_assignment" "az_gw2_cluster_ip" {
    scope = azurerm_resource_group.trustgrid.id
    role_definition_name = module.trustgrid_cluster_ip_role.name
    principal_id = module.az_gw2.principal_id
}

## Create Roles Required for Cluster Routes and Assign to the Trustgrid Gateways


module "trustgrid_cluster_route_role" {
    source = "github.com/trustgrid/trustgrid-infra-as-code//azure/terraform/modules/authorization/trustgrid_cluster_route_role?ref=v0.2.0"
    name_prefix = var.environment_prefix
    scope = data.azurerm_subscription.current.id
    assignable_scopes = [ data.azurerm_subscription.current.id ]  
    ## If the cluster needs to update route tables in other subscriptions, then the assignable_scopes should be the list of subscriptions that the cluster can manage routes in. 
    ## You would also need additional role assignments with scopes in those subscriptions that include the needed route tables.
}

### Assign the role to the Trustgrid Gateways
resource "azurerm_role_assignment" "az_gw1_cluster_route_network" {
    scope = azurerm_resource_group.trustgrid.id
    role_definition_name = module.trustgrid_cluster_route_role.name
    principal_id = module.az_gw1.principal_id
}


resource "azurerm_role_assignment" "az_gw2_cluster_route_network" {
    scope = azurerm_resource_group.trustgrid.id
    role_definition_name = module.trustgrid_cluster_route_role.name
    principal_id = module.az_gw2.principal_id
}
