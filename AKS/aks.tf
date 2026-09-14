resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${local.name}-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${local.name}-aks"

  kubernetes_version = "1.34"

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name       = "system"
    vm_size    = "Standard_B2s"
    node_count = 1

    vnet_subnet_id = azurerm_subnet.aks.id

    type            = "VirtualMachineScaleSets"
    os_disk_size_gb = 30
    max_pods        = 30

    tags = local.tags
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
  }

  tags = local.tags
}