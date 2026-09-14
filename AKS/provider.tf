locals {
  location = "East US"

  name = "netflix"

  vnet_address_space = "172.16.0.0/24"
  aks_subnet         = "172.16.1.0/24"

  tags = {
    Project     = "netflix"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}