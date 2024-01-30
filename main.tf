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
  businessUnitLower = lower(var.business_unit)
  businessUnitUpper = upper(var.business_unit)
  appNameLower      = lower(var.application_name)
}


resource "azurerm_resource_group" "rg" {
  for_each = { for env in var.environments : env.envname => env }

  name = "rg-${local.businessUnitLower}-${local.appNameLower}-${each.value.envname}-${var.azure_resource_location_naming_keyword}"
  # different naming convention with focus on business unit
  #name     = "${local.businessUnitUpper}-${var.application_name}-${each.value.envname}-${var.azure_resource_location_naming_keyword}"

  location = var.azure_location

  tags = {
    env = "${each.value.envname}"
  }
}

resource "azurerm_virtual_network" "vnet" {
  for_each = { for env in var.environments : env.envname => env }

  name                = "vnet-databricks-${each.value.envname}"
  address_space       = each.value.vnet.address_space
  location            = azurerm_resource_group.rg[each.value.envname].location
  resource_group_name = azurerm_resource_group.rg[each.value.envname].name
}

resource "azurerm_subnet" "public" {
  for_each = { for env in var.environments : env.envname => env }

  name                 = "snet-public-${each.value.envname}"
  resource_group_name  = azurerm_resource_group.rg[each.value.envname].name
  virtual_network_name = azurerm_virtual_network.vnet[each.value.envname].name
  address_prefixes     = each.value.vnet.public_subnet_address_prefixes

  delegation {
    name = "databricks-${each.value.envname}-del"

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
  for_each = { for env in var.environments : env.envname => env }

  name                 = "snet-private-${each.value.envname}"
  resource_group_name  = azurerm_resource_group.rg[each.value.envname].name
  virtual_network_name = azurerm_virtual_network.vnet[each.value.envname].name
  address_prefixes     = each.value.vnet.private_subnet_address_prefixes

  delegation {
    name = "databricks-${each.value.envname}-del"

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
  for_each = { for env in var.environments : env.envname => env }

  subnet_id                 = azurerm_subnet.private[each.value.envname].id
  network_security_group_id = azurerm_network_security_group.nsg[each.value.envname].id
}

resource "azurerm_subnet_network_security_group_association" "public" {
  for_each = { for env in var.environments : env.envname => env }

  subnet_id                 = azurerm_subnet.public[each.value.envname].id
  network_security_group_id = azurerm_network_security_group.nsg[each.value.envname].id
}

resource "azurerm_network_security_group" "nsg" {
  for_each = { for env in var.environments : env.envname => env }

  name                = "nsg-databricks-${each.value.envname}"
  location            = azurerm_resource_group.rg[each.value.envname].location
  resource_group_name = azurerm_resource_group.rg[each.value.envname].name
}


resource "azurerm_databricks_workspace" "dbw" {
  for_each = { for env in var.environments : env.envname => env }

  resource_group_name = azurerm_resource_group.rg[each.value.envname].name
  location            = azurerm_resource_group.rg[each.value.envname].location
  name                = "dbw-${local.businessUnitLower}-${local.appNameLower}-${each.value.envname}"
  # different naming convention with focus on business unit
  #name                = "${local.businessUnitLower}-dbw-${each.value.envname}"

  sku = "premium"

  managed_resource_group_name = "dbw-${local.businessUnitLower}-${local.appNameLower}-${each.value.envname}-managed"
  # different naming convention with focus on business unit
  #managed_resource_group_name = "${local.businessUnitUpper}-${var.application_name}-${each.value.envname}-managed"

  public_network_access_enabled = true

  custom_parameters {
    no_public_ip        = true
    public_subnet_name  = azurerm_subnet.public[each.value.envname].name
    private_subnet_name = azurerm_subnet.private[each.value.envname].name
    virtual_network_id  = azurerm_virtual_network.vnet[each.value.envname].id

    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.public[each.value.envname].id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.private[each.value.envname].id
  }

  tags = {
    env = "${each.value.envname}"
  }
}


module "storage-account" {
  for_each = { for env in var.environments : env.envname => env }
  source   = "./modules/storage-account"

  rg_name        = azurerm_resource_group.rg[each.value.envname].name
  location       = azurerm_resource_group.rg[each.value.envname].location
  name_key       = "${local.businessUnitLower}${each.value.envname}"
  name_suffix    = "dbw"
  container_name = "datalake"

  account_kind             = each.value.storage.account_kind
  account_tier             = each.value.storage.account_tier
  account_replication_type = each.value.storage.account_replication_type
  is_hns_enabled           = each.value.storage.is_hns_enabled

  tags = {
    env = "${each.value.envname}"
  }
}

