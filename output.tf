output "ip" {
  value = proxmox_vm_qemu.proxmox_vm[*].ssh_host
}

output "mac" {
  value = proxmox_vm_qemu.proxmox_vm[*].network[0].macaddr
}

output "id" {
  value = proxmox_vm_qemu.proxmox_vm[*].id
}
