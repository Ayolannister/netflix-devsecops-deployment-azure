##############################
# Resource Group
##############################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

##############################
# Networking (VNet + Subnet)
# Replaces the AWS var.vpc_id / var.subnet_id inputs — Azure creates its own network here
##############################
resource "azurerm_virtual_network" "vnet" {
  name                = "netflix-vnet"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "netflix-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_address_prefix
}

##############################
# Network Security Group
# Same 5 inbound rules as the AWS security-group module (Jenkins, HTTPS, HTTP, SSH, SonarQube)
# Azure NSGs allow all outbound by default, so no explicit egress rule is needed
# (the AWS module's "all traffic" egress_with_cidr_blocks rule has no Azure equivalent to add)
##############################
resource "azurerm_network_security_group" "nsg" {
  name                = "netflix-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Jenkins"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SonarQube"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

##############################
# Public IP
# Replaces aws_eip
##############################
resource "azurerm_public_ip" "pip" {
  name                = "netflix-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Name        = "netflix-server"
  }
}

##############################
# Network Interface
##############################
resource "azurerm_network_interface" "nic" {
  name                = "netflix-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

##############################
# Virtual Machine
# Replaces the AWS ec2-instance module
# ami/key_pair -> source_image_reference/admin_ssh_key, instance_type -> size,
# root_block_device -> os_disk, user_data -> custom_data
##############################
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "netflix-server"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS" # closest equivalent to AWS gp3
    disk_size_gb         = var.os_disk_size_gb
  }

  # Rocky Linux (RPM/yum-based) — closest Azure Marketplace equivalent to Amazon Linux,
  # since userdata.sh is yum-based. Ubuntu could be used instead if you're open to
  # rewriting userdata.sh for apt.
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Some third-party Marketplace images (like Rocky Linux from "resf") require accepting
  # marketplace terms once per subscription before Terraform can deploy them:
  #   az vm image terms accept --publisher resf --offer rockylinux-x86_64 --plan 9-lvm


  custom_data = base64encode(templatefile("${path.module}/userdata.sh", {
    admin_username = var.admin_username
  }))

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Name        = "netflix-server"
  }
}

output "public_ip_address" {
  description = "Public IP address of the netflix-server VM"
  value       = azurerm_public_ip.pip.ip_address
}
