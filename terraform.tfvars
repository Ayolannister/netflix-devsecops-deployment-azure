resource_group_name = "netflix-rg"
location            = "East US"

vm_size = "Standard_B2s"

admin_username = "azureuser"

ssh_public_key_path = "/home/lxnnister/.ssh/demo-task_key.pub"

vnet_address_space = [
  "172.16.0.0/16"
]

subnet_address_prefix = [
  "172.16.0.0/24"
]

os_disk_size_gb = 32