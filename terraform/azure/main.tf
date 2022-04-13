# Configure Azure Provider
terraform {
  backend "azurerm" {
    key = "demo.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# Variables
variable "aks_name" {}
variable "rg_aks" {
  default = "rg-aks-test"
}
variable "location" {
  default = "East US"
}
variable "node_pool_size" {}

resource "azurerm_resource_group" "rg-aks" {
  name     = var.rg_aks
  location = var.location
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = var.aks_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-aks.name
  dns_prefix          = var.aks_name

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = var.node_pool_size
  }
}

output "client_certificate" {
  value = azurerm_kubernetes_cluster.example.kube_config.0.client_certificate
  sensitive = true
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.example.kube_config_raw
  sensitive = true
}
