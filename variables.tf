variable "business_unit" {
  type        = string
  default     = ""
  description = "Business unit keyword to be used in resource names."
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
  type        = list(string)
  default     = ["dev"]
  description = "List of environments. For each environment a resource group with a databricks workspace, storage account, key vault etc. will be created."
}
