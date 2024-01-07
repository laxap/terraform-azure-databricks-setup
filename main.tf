terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.82.0"
    }
  }
  #cloud {
  #  organization = ""
  #  workspaces {
  #    name = "databricks-setup"
  #  }
  #}
}

provider "azurerm" {
  features {
  }
}

locals {
  # if var.bunit is not empty appends a slash "-" 
  business_unit = "${var.business_unit}${var.business_unit != "" ? "-" : ""}"
}


# For each environment create an Azure resource group, vnets, databricks workspace and storage account
# 
resource "azurerm_resource_group" "rg" {
  for_each = toset(var.environments)

  name     = "rg-${local.business_unit}databricks-${each.key}-${var.azure_resource_location_naming_keyword}"
  location = var.azure_location

  tags = {
    env = "${each.key}"
  }
}

resource "azurerm_virtual_network" "vnet" {
  for_each = toset(var.environments)

  name                = "vnet-databricks-${each.key}"
  address_space       = ["10.139.0.0/16"]
  location            = azurerm_resource_group.rg[each.key].location
  resource_group_name = azurerm_resource_group.rg[each.key].name
}

resource "azurerm_subnet" "public" {
  for_each = toset(var.environments)

  name                 = "snet-public-${each.key}"
  resource_group_name  = azurerm_resource_group.rg[each.key].name
  virtual_network_name = azurerm_virtual_network.vnet[each.key].name
  address_prefixes     = ["10.139.0.0/18"]

  delegation {
    name = "databricks-${each.key}-del"

    service_delegation {
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
      name = "Microsoft.Databricks/workspaces"
    }
  }
}

resource "azurerm_subnet" "private" {
  for_each = toset(var.environments)

  name                 = "snet-private-${each.key}"
  resource_group_name  = azurerm_resource_group.rg[each.key].name
  virtual_network_name = azurerm_virtual_network.vnet[each.key].name
  address_prefixes     = ["10.139.64.0/18"]

  delegation {
    name = "databricks-${each.key}-del"

    service_delegation {
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
      name = "Microsoft.Databricks/workspaces"
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "private" {
  for_each = toset(var.environments)

  subnet_id                 = azurerm_subnet.private[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}

resource "azurerm_subnet_network_security_group_association" "public" {
  for_each = toset(var.environments)

  subnet_id                 = azurerm_subnet.public[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}

resource "azurerm_network_security_group" "nsg" {
  for_each = toset(var.environments)

  name                = "nsg-databricks-${each.key}"
  location            = azurerm_resource_group.rg[each.key].location
  resource_group_name = azurerm_resource_group.rg[each.key].name
}



# see https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/databricks_workspace
#
resource "azurerm_databricks_workspace" "dbw" {
  for_each = toset(var.environments)

  resource_group_name         = azurerm_resource_group.rg[each.key].name
  location                    = azurerm_resource_group.rg[each.key].location
  name                        = "dbw-${local.business_unit}${each.key}"
  sku                         = "premium"
  managed_resource_group_name = "rg-${local.business_unit}databricks-${each.key}-managed-services"

  public_network_access_enabled = true

  custom_parameters {
    no_public_ip        = true
    public_subnet_name  = azurerm_subnet.public[each.key].name
    private_subnet_name = azurerm_subnet.private[each.key].name
    virtual_network_id  = azurerm_virtual_network.vnet[each.key].id

    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.public[each.key].id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.private[each.key].id
  }

  tags = {
    env = "${each.key}"
  }
}


module "storage-account" {
  for_each = toset(var.environments)
  source   = "./modules/storage-account"

  rg_name        = azurerm_resource_group.rg[each.key].name
  location       = var.azure_location
  name_key       = "${var.business_unit}${each.key}"
  name_suffix    = "dbw"
  container_name = "datalake"

  tags = {
    env = "${each.key}"
  }
}

