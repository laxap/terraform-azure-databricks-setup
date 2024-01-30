variable "business_unit" {
  type        = string
  default     = "BI"
  description = "Business unit keyword to be used in resource names."
}

variable "application_name" {
  type        = string
  default     = "Analytics"
  description = "Application/workload keyword to be used in resource names."
}

variable "azure_location" {
  type        = string
  default     = "West Europe"
  description = "The region to create the resources."
}
variable "azure_resource_location_naming_keyword" {
  type        = string
  default     = "euwest"
  description = "The location keyword to be used in resource names."
}

variable "environments" {
  type = list(object({
    envname = string,
    storage = object({
      account_kind             = string,
      account_tier             = string,
      account_replication_type = string,
      is_hns_enabled           = bool
    }),
    vnet = object({
      address_space                   = list(string),
      public_subnet_address_prefixes  = list(string),
      private_subnet_address_prefixes = list(string)
    })
  }))

  default = [
    /*{
      envname = "sandbox",
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
    },*/
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
    },
    /*{
      envname = "int",
      storage = {
        account_kind             = "StorageV2",
        account_tier             = "Standard",
        account_replication_type = "LRS", # GRS
        is_hns_enabled           = true
      },
      vnet = {
        address_space                   = ["10.139.0.0/16"],
        public_subnet_address_prefixes  = ["10.139.0.0/18"],
        private_subnet_address_prefixes = ["10.139.64.0/18"]
      }
    },*/
    {
      envname = "prod",
      storage = {
        account_kind             = "StorageV2",
        account_tier             = "Standard",
        account_replication_type = "LRS", # GRS
        is_hns_enabled           = true
      },
      vnet = {
        address_space                   = ["10.139.0.0/16"],
        public_subnet_address_prefixes  = ["10.139.0.0/18"],
        private_subnet_address_prefixes = ["10.139.64.0/18"]
      }
    }
  ]
  description = "List of environment definitions."
}
