resource "azurerm_resource_group" "main" {
  name     = "netflix-rg"
  location = local.location

  tags = local.tags
}