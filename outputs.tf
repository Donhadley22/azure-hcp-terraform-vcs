output "resource_group_name" {
  description = "The name of the created resource group"
  value       = azurerm_resource_group.rg.name
}

output "public_ip_address" {
  description = "The public IP address of the virtual machine"
  value       = azurerm_public_ip.public_ip.ip_address
}

output "vm_name" {
  description = "The name of the virtual machine"
  value       = azurerm_linux_virtual_machine.vm.name
}

