module "proxmox-vm" {
  source                  = "../."
  pve_api_url             = var.pve_api_url
  pve_api_user            = var.pve_api_user
  pve_api_password        = var.pve_api_password
  pve_api_tls_verify      = var.pve_api_tls_verify

  pve_cluster_node        = "sthings-pve1"
  pve_datastore           = "{{ pve_datastore }}"
  pve_folder_path         = "stuttgart-things"
  pve_network             = "{{ pve_network }}"
  vm_count                = {{ vm_count }}
  vm_name                 = "{{ name }}"
  vm_notes                = "vm-info"
  vm_template             = "ubuntu22"
  vm_num_cpus             = "{{ vm_num_cpus }}"
  vm_memory               = {{ vm_memory }}
  vm_disk_size            = "{{ vm_disk_size }}"
  vm_ssh_user             = var.vm_ssh_user
  vm_ssh_password         = var.vm_ssh_password
}

output "ip" {
  value     = module.proxmox-vm.ip
}

output "mac" {
  value     = module.proxmox-vm.mac
}

output "id" {
  value     = module.proxmox-vm.id
}


variable "pve_api_url" {
  description = "url of proxmox api"
}
 
variable "pve_api_user" {
  description = "username of proxmox api user"
}
 
variable "pve_api_password" {
  description = "password of proxmox api user"
}
 
variable "vm_ssh_user" {
  description = "username of proxmox api user"
}
 
variable "vm_ssh_password" {
  description = "password of proxmox api user"
}
 
variable "pve_api_tls_verify" {
  description = "proxmox API disable check if cert is valid"
}