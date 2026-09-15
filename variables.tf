variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
}

variable "location" {
  description = "Azure region to deploy into"
  type        = string
}

variable "vm_size" {
  description = "Azure VM size (equivalent to AWS instance_type)"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VM (SSH login)"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the local SSH public key file used to authenticate to the VM (replaces AWS key_pair)"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
}

variable "subnet_address_prefix" {
  description = "Address prefix for the subnet (replaces AWS subnet_id — this subnet is created, not looked up)"
  type        = list(string)
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB (equivalent to AWS root_block_device volume_size)"
  type        = number
}
