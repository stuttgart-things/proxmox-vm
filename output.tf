output "ip" {
  value = proxmox_vm_qemu.proxmox_vm[*].default_ipv4_address
}

output "mac" {
  value = proxmox_vm_qemu.proxmox_vm[*].network[0].macaddr
}

output "id" {
  value = proxmox_vm_qemu.proxmox_vm[*].id
}

output "name" {
  description = "Names of the created VMs, in count order."
  value       = proxmox_vm_qemu.proxmox_vm[*].name
}

output "vmid" {
  description = "Proxmox VMIDs, as numbers (the `id` output is the provider's node/qemu/<vmid> resource id string)."
  value       = proxmox_vm_qemu.proxmox_vm[*].vmid
}

output "ipv6" {
  description = "IPv6 addresses, when the guest agent reports one."
  value       = proxmox_vm_qemu.proxmox_vm[*].default_ipv6_address
}
