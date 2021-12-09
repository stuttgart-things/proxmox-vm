variable "pve_cluster_node" {
  default         = false
  description     = "name of proxmox cluster node"
}

variable "pve_folder_path" {
  default         = false
  description     = "target (vm) folder path of proxmox virtual machine"
}

variable "pve_datastore" {
  default         = false
  description     = "name of proxmox datastore"
}

variable "pve_network" {
  default         = false
  description     = "name of proxmox network"
}

variable "vm_numa" {
  default         = true
  description     = "enable numa for vm"
}

variable "vm_firmware" {
  default         = "seabios"
  description     = "the firmware interface to use on the virtual machine. Can be one of bios or EFI. Default: bios"
}

variable "vm_os_type" {
  default         = "l26"
  description     = "the type of OS in the guest to allow Proxmox to enable optimizations for the appropriate guest OS"
}

variable "vm_count"{
  default         = 1
  description     = "count of vms"
}

variable "vm_name" {
  default         = "terraform-vm"
  description     = "name of proxmox virtual machine"
}

variable "vm_guest_agent" {
  default         = 1
  description     = "QEMU Guest Agent configuration set 0 to disable 1 to enable"
}

variable "vm_notes" {
  default         = false
  description     = "notes of proxmox virtual machine shwon in UI"
}

variable "vm_template" {
  default         = false
  description     = "name of proxmox virtual machine template"
}

variable "vm_num_cpus" {
  default         = 2
  description     = "amount of cpus of the vm"
}

variable "vm_num_sockets" {
  default         = 1
  description     = "amount of sockets of the vm"
}

variable "vm_memory" {
  default         = 2048
  description     = "amount of memory of the vm"
}

variable "vm_disk_size" {
  default         = "30G"
  description     = "size of disk"
}

variable "vm_disk_type" {
  default         = "virtio"
  description     = "type of disk"
}

variable "vm_bootdisk" {
  default         = "virtio0"
  description     = "default boot disk"
}

variable "vm_storage_controller" {
  default         = "virtio-scsi-pci"
  description     = "storage controller to emulate"
}

variable "vm_network_type" {
  default         = "virtio"
  description     = "network card type"
}

variable "vm_ssh_user" {
  default         = ""
  description     = "Username of VM"
}

variable "vm_ssh_password" {
  default         = ""
  description     = "Password of VM user"
}

variable "vm_network_address0" {
  default         = "ip=dhcp"
  description     = "The first IP address to assign to the guest (set to ip=dhcp to get a ip output)"
}
