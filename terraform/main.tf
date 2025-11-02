# Random pet name for resource group
resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = random_pet.rg_name.id
  location = var.resource_group_location
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-nginx-lb"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "subnet-internal"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public Security Group (for load balancer VM)
resource "azurerm_network_security_group" "public_nsg" {
  name                = "nsg-public"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
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
    priority                   = 1002
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
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Private Security Group (for backend web servers)
resource "azurerm_network_security_group" "private_nsg" {
  name                = "nsg-private"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH-Internal"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP-Internal"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }
}

# SSH Key generation using Azure API
resource "random_pet" "ssh_key_name" {
  prefix    = "ssh"
  separator = ""
}

resource "azapi_resource" "ssh_public_key" {
  type      = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name      = random_pet.ssh_key_name.id
  location  = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id
}

resource "azapi_resource_action" "ssh_public_key_gen" {
  type        = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id = azapi_resource.ssh_public_key.id
  action      = "generateKeyPair"
  method      = "POST"

  response_export_values = ["publicKey", "privateKey"]
}

# Random ID for storage account
resource "random_id" "random_id" {
  keepers = {
    resource_group = azurerm_resource_group.rg.name
  }
  byte_length = 8
}

# Storage account for boot diagnostics
resource "azurerm_storage_account" "storage_account" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Random string for domain name label
resource "random_string" "domain_label" {
  length  = 8
  special = false
  upper   = false
}

# Public IP for Load Balancer VM with domain name label
resource "azurerm_public_ip" "lb_public_ip" {
  name                = "pip-lb-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "nginx-lb-${random_string.domain_label.result}"
}

# Network Interface for Load Balancer VM (VM-1)
resource "azurerm_network_interface" "lb_nic" {
  name                = "nic-vm-1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lb_public_ip.id
  }
}

# Associate Public NSG with Load Balancer NIC
resource "azurerm_network_interface_security_group_association" "lb_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.lb_nic.id
  network_security_group_id = azurerm_network_security_group.public_nsg.id
}

# Load Balancer VM (VM-1)
resource "azurerm_linux_virtual_machine" "lb_vm" {
  name                = "VM-1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = var.username
  network_interface_ids = [
    azurerm_network_interface.lb_nic.id,
  ]

  admin_ssh_key {
    username   = var.username
    public_key = azapi_resource_action.ssh_public_key_gen.output.publicKey
  }

  os_disk {
    name                 = "osdisk-vm-1"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.storage_account.primary_blob_endpoint
  }
}

# Network Interfaces for Backend VMs (VM-2, VM-3, VM-4)
resource "azurerm_network_interface" "backend_nic" {
  count               = 3
  name                = "nic-vm-${count.index + 2}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Associate Private NSG with Backend NICs
resource "azurerm_network_interface_security_group_association" "backend_nsg_assoc" {
  count                     = 3
  network_interface_id      = azurerm_network_interface.backend_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.private_nsg.id
}

# Backend VMs (VM-2, VM-3, VM-4)
resource "azurerm_linux_virtual_machine" "backend_vm" {
  count               = 3
  name                = "VM-${count.index + 2}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = var.username
  network_interface_ids = [
    azurerm_network_interface.backend_nic[count.index].id,
  ]

  admin_ssh_key {
    username   = var.username
    public_key = azapi_resource_action.ssh_public_key_gen.output.publicKey
  }

  os_disk {
    name                 = "osdisk-vm-${count.index + 2}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.storage_account.primary_blob_endpoint
  }
}

# Outputs
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "lb_public_ip_address" {
  value = azurerm_public_ip.lb_public_ip.ip_address
}

output "lb_fqdn" {
  value       = azurerm_public_ip.lb_public_ip.fqdn
  description = "Fully qualified domain name for the load balancer"
}

output "backend_vm_private_ips" {
  value = azurerm_network_interface.backend_nic[*].private_ip_address
}

output "ssh_private_key" {
  value     = azapi_resource_action.ssh_public_key_gen.output.privateKey
  sensitive = true
}

output "ssh_public_key" {
  value = azapi_resource_action.ssh_public_key_gen.output.publicKey
}