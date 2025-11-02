output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "The name of the resource group"
}

output "location" {
  value       = azurerm_resource_group.rg.location
  description = "The Azure region where resources are deployed"
}

output "lb_public_ip_address" {
  value       = azurerm_public_ip.lb_public_ip.ip_address
  description = "Public IP address of the load balancer VM"
}

output "lb_fqdn" {
  value       = azurerm_public_ip.lb_public_ip.fqdn
  description = "Fully qualified domain name for the load balancer"
}

output "lb_vm_name" {
  value       = azurerm_linux_virtual_machine.lb_vm.name
  description = "Name of the load balancer VM"
}

output "lb_vm_private_ip" {
  value       = azurerm_network_interface.lb_nic.private_ip_address
  description = "Private IP address of the load balancer VM"
}

output "backend_vm_names" {
  value       = azurerm_linux_virtual_machine.backend_vm[*].name
  description = "Names of the backend VMs"
}

output "backend_vm_private_ips" {
  value       = azurerm_network_interface.backend_nic[*].private_ip_address
  description = "Private IP addresses of the backend VMs"
}

output "backend_vm_ids" {
  value       = azurerm_linux_virtual_machine.backend_vm[*].id
  description = "Azure resource IDs of the backend VMs"
}

output "vnet_name" {
  value       = azurerm_virtual_network.vnet.name
  description = "Name of the virtual network"
}

output "subnet_name" {
  value       = azurerm_subnet.subnet.name
  description = "Name of the subnet"
}

output "subnet_address_prefix" {
  value       = azurerm_subnet.subnet.address_prefixes[0]
  description = "Address prefix of the subnet"
}

output "admin_username" {
  value       = var.username
  description = "Admin username for SSH access"
}

output "ssh_public_key" {
  value       = azapi_resource_action.ssh_public_key_gen.output.publicKey
  description = "SSH public key for the VMs"
}

output "ssh_private_key" {
  value       = azapi_resource_action.ssh_public_key_gen.output.privateKey
  sensitive   = true
  description = "SSH private key for the VMs (sensitive)"
}

output "storage_account_name" {
  value       = azurerm_storage_account.storage_account.name
  description = "Name of the storage account for boot diagnostics"
}

output "connection_string" {
  value       = "ssh ${var.username}@${azurerm_public_ip.lb_public_ip.ip_address}"
  description = "SSH connection string for the load balancer VM"
}

output "connection_string_fqdn" {
  value       = "ssh ${var.username}@${azurerm_public_ip.lb_public_ip.fqdn}"
  description = "SSH connection string using FQDN for the load balancer VM"
}

output "deployment_summary" {
  value = <<-EOT
    ========================================
    Deployment Summary
    ========================================
    Resource Group: ${azurerm_resource_group.rg.name}
    Location: ${azurerm_resource_group.rg.location}
    
    Load Balancer VM (${azurerm_linux_virtual_machine.lb_vm.name}):
      - Public IP: ${azurerm_public_ip.lb_public_ip.ip_address}
      - FQDN: ${azurerm_public_ip.lb_public_ip.fqdn}
      - Private IP: ${azurerm_network_interface.lb_nic.private_ip_address}
      - SSH: ssh ${var.username}@${azurerm_public_ip.lb_public_ip.ip_address}
      - HTTP: http://${azurerm_public_ip.lb_public_ip.ip_address}
      - HTTPS: https://${azurerm_public_ip.lb_public_ip.ip_address}
    
    Backend VMs:
      - VM-2: ${azurerm_network_interface.backend_nic[0].private_ip_address}
      - VM-3: ${azurerm_network_interface.backend_nic[1].private_ip_address}
      - VM-4: ${azurerm_network_interface.backend_nic[2].private_ip_address}
    
    Network:
      - VNet: ${azurerm_virtual_network.vnet.name}
      - Subnet: ${azurerm_subnet.subnet.name} (${azurerm_subnet.subnet.address_prefixes[0]})
    
    To save SSH private key:
      terraform output -raw ssh_private_key > ~/.ssh/azure_lb_key
      chmod 600 ~/.ssh/azure_lb_key
      ssh -i ~/.ssh/azure_lb_key ${var.username}@${azurerm_public_ip.lb_public_ip.ip_address}
    ========================================
  EOT
  description = "Complete deployment summary with all important information"
}
