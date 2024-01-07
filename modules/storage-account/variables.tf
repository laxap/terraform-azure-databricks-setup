variable "rg_name" {
  type        = string
  description = "The name of the resource group."
}
variable "location" {
  type        = string
  description = "The Azure region."
}

variable "name_key" {
  type     = string
  nullable = false
}
variable "name_suffix" {
  type    = string
  default = ""
}
variable "account_kind" {
  type     = string
  default  = "StorageV2"
  nullable = false
}
variable "account_tier" {
  type     = string
  default  = "Standard"
  nullable = false
}
variable "account_replication_type" {
  type     = string
  default  = "LRS"
  nullable = false
}
variable "is_hns_enabled" {
  type     = bool
  default  = true
  nullable = false
}

variable "container_name" {
  type        = string
  nullable    = false
  description = "The name of the container to create in the storage account."
}
variable "container_access_type" {
  type     = string
  default  = "private"
  nullable = false
}

variable "tags" {}