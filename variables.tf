variable "pve_cluster_node" {
  default     = false
  type        = string
  description = "name of proxmox cluster node"
}

variable "pve_folder_path" {
  default     = false
  type        = string
  description = "target (vm) folder path of proxmox virtual machine"
}

variable "pve_datastore" {
  default     = false
  type        = string
  description = "name of proxmox datastore"
}

variable "pve_network" {
  default     = false
  type        = string
  description = "name of proxmox network"
}

variable "vm_numa" {
  default     = true
  type        = bool
  description = "enable numa for vm"
}

variable "vm_onboot" {
  default     = true
  type        = bool
  description = "whether to have the VM startup after the PVE node starts"
}

variable "vm_firmware" {
  default     = "seabios"
  type        = string
  description = "the firmware interface to use on the virtual machine. Can be one of bios or EFI. Default: bios"
}

variable "vm_os_type" {
  default     = "l26"
  type        = string
  description = "the type of OS in the guest to allow Proxmox to enable optimizations for the appropriate guest OS"
}

variable "vm_count" {
  default     = 1
  type        = number
  description = "count of vms"

  validation {
    condition     = var.vm_count >= 1 && var.vm_count <= 5 && floor(var.vm_count) == var.vm_count
    error_message = "Accepted values: 1-5."
  }

}

variable "vm_name" {
  default     = false
  type        = string
  description = "name of proxmox virtual machine"
}

variable "vm_guest_agent" {
  default     = 1
  type        = number
  description = "QEMU Guest Agent configuration set 0 to disable 1 to enable"
}

variable "vm_notes" {
  default     = false
  type        = string
  description = "notes of proxmox virtual machine shwon in UI"
}

variable "vm_template" {
  default     = false
  type        = string
  description = "name of proxmox virtual machine template"
}

variable "vm_num_cpus" {
  default     = 2
  type        = number
  description = "amount of cpus of the vm"

  validation {
    condition     = contains([2, 4, 6, 8, 10, 12, 16], var.vm_num_cpus)
    error_message = "Valid values for vm_num_cpus are (2, 4, 6, 8, 10, 12, 16)"
  }

}

variable "vm_num_sockets" {
  default     = 1
  type        = number
  description = "amount of sockets of the vm"
}

variable "vm_memory" {
  default     = 4096
  type        = number
  description = "amount of memory of the vm"
  
  validation {
    condition     = contains([1024, 2048, 4096, 8192], var.vm_memory)
    error_message = "Valid values for vm_memory are (1024, 2048, 4096, 8192)"
  }
}

variable "vm_disk_size" {
  default     = "32G"
  description = "size of disk"
  type        = string

  validation {
    condition     = contains(["20G", "32G", "64G", "96G", "128G", "196G", "256G"], var.vm_disk_size)
    error_message = "Valid values for vm_disk_size are (20G, 32G, 64G, 96G, 128G, 196G, 256G)"
  }

}

variable "vm_disk_type" {
  default     = "virtio"
  type        = string
  description = "type of disk"
}

variable "vm_bootdisk" {
  default     = "virtio0"
  type        = string
  description = "default boot disk"
}

variable "vm_storage_controller" {
  default     = "virtio-scsi-pci"
  type        = string
  description = "storage controller to emulate"
}

variable "vm_network_type" {
  default     = "virtio"
  type        = string
  description = "network card type"
}

variable "vm_ssh_user" {
  default     = ""
  type        = string
  description = "Username of VM"
}

variable "vm_ssh_password" {
  default     = ""
  type        = string
  description = "Password of VM user"
}

variable "vm_network_address0" {
  default     = "ip=dhcp"
  type        = string
  description = "The first IP address to assign to the guest (set to ip=dhcp to get a ip output)"
}

variable "vm_macaddr" {
  default     = null
  type        = string
  description = "Mac address of desired vm"
}

variable "pve_api_url" {
  default     = false
  type        = string
  description = "url of proxmox api"
}

variable "pve_api_user" {
  default     = false
  type        = string
  description = "username of proxmox api user"
}

variable "pve_api_password" {
  default     = false
  type        = string
  description = "password of proxmox api user"
}

variable "pve_api_tls_verify" {
  default     = true
  type        = bool
  description = "proxmox API disable check if cert is valid"
}
