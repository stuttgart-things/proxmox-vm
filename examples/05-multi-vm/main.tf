# ============================================================================
# 05 — MULTIPLE VMs FROM ONE CALL
#
# vm_count fans the module out over 1-5 VMs. NAMING IS ASYMMETRIC BY DESIGN and
# predates this example: the first VM keeps the bare name, later ones get a
# 1-based suffix.
#
#   vm_count = 3, vm_name = "worker"  ->  worker, worker-2, worker-3
#
# Consequences worth knowing before you rely on it:
#   * Do NOT set vm_id here — every VM would ask for the same VMID.
#   * vm_network_address0 is shared, so a static IP would collide. DHCP is the
#     only sane option for vm_count > 1 with a single ipconfig0.
#   * Removing a middle VM is not possible: count re-indexes, so dropping
#     vm_count from 3 to 2 destroys worker-3, not the one you had in mind.
# ============================================================================

module "vms" {
  source = "../../"

  pve_api_url        = var.pve_api_url
  pve_api_user       = var.pve_api_user
  pve_api_password   = var.pve_api_password
  pve_api_tls_verify = var.pve_api_tls_verify

  pve_cluster_node = "sthings-pve1"
  pve_datastore    = "datastore"
  pve_folder_path  = "stuttgart-things"
  pve_network      = "vmbr101"

  vm_count    = 3
  vm_name     = "worker"
  vm_template = "ubuntu24-cloudinit"

  vm_num_cpus  = 4
  vm_memory    = 8192
  vm_disk_size = "64G"

  vm_network_address0 = "ip=dhcp"

  vm_cloudinit_datastore = "local-lvm"

  vm_ci_os_type  = "cloud-init"
  vm_ci_user     = "sthings"
  vm_ci_ssh_keys = var.ci_ssh_keys

  vm_tags = ["terraform", "worker"]
}

variable "ci_ssh_keys" {
  type = list(string)
}

# Zip names and addresses into something an inventory generator can consume.
output "inventory" {
  value = zipmap(module.vms.name, module.vms.ip)
}
