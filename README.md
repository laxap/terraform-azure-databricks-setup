# Terraform configuration to setup multiple vnet-injected Databricks workspaces in Azure

> Initially this configuration was created to get an understanding of Terraform.

For each environment defined in the variable _environments_ the following Azure resources will be created:

- Resource Group
    - Azure Databricks Service
    - Storage account
    - Network security group
    - Virtual network with public and private subnet
    - Access Connector for Azure Databricks
- Managed Resource Group
    - Managed Identity
    - Storage Account
    - Access Connector for Azure Databricks (for Unity catalog)

The _environments_ variable contains a list of objects. In each object the environment name and the settings for the storage account and virtual networks of each environment have to be provided. The following code block shows an example of a object defining one environment.

```json
{
    envname = "dev",
    storage = {
        account_kind             = "StorageV2",
        account_tier             = "Standard",
        account_replication_type = "LRS",
        is_hns_enabled           = true
    },
    vnet = {
        address_space                   = ["10.139.0.0/16"],
        public_subnet_address_prefixes  = ["10.139.0.0/18"],
        private_subnet_address_prefixes = ["10.139.64.0/18"]
    }
}
```

Additional variables are provided for:

- Business unit name
    - used in the resource group name and Databricks workspace name
- Application/workspace name
    - used in the resource group name and Databricks workspace name
- Azure location (region) where the resources are created


