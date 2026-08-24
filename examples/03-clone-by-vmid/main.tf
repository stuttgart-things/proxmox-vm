# ============================================================================
# 03 — CLONE BY VMID, PINNED VMID, VLAN
#
# Clone by numeric template ID rather than by name. Use this when template
# names are ambiguous across the cluster, or when your source of truth tracks
# IDs — the Crossplane NativeProxmoxVM XR's `vm.templateVmId` does exactly this.
#
# vm_template and vm_clone_id are mutually exclusive; setting both fails a
# precondition rather than letting the provider pick one.
#
# EVERYTHING HERE IS CREATE-ONLY:
#   * vm_clone_id / vm_full_clone force replacement on change
#   * vm_id must only be set on a VM that does not exist yet
#   * vm_vlan_tag lands inside the ignored `network` block, so re-tagging a
#     live VM through Terraform is silently dropped
# ============================================================================

module "vm" {
  source = "../../"

  pve_api_url        = var.pve_api_url
  pve_api_user       = var.pve_api_user
  pve_api_password   = var.pve_api_password
  pve_api_tls_verify = var.pve_api_tls_verify

  pve_cluster_node = "ul-pve02"
  pve_datastore    = "V5010-01-1"
  pve_folder_path  = "stuttgart-things"
  pve_network      = "vmbrvlan" # a VLAN-AWARE bridge; tagging a plain bridge does nothing

  vm_name = "by-vmid"

  # --- opt-in: clone source ---
  # 144 = ubuntu26-base-os. NOTE (2026-08-24): 144 lives on ul-pve11, which
  # currently cannot clone — every storage call there times out. Use 110 on
  # ul-pve10 until that is fixed. See docs/labul-ul-pve11-incident.md.
  vm_clone_id   = 144
  vm_full_clone = true # not a linked clone: survives deleting the template

  # --- opt-in: pinned VMID ---
  vm_id = 9144

  # --- opt-in: VLAN ---
  vm_vlan_tag = 102

  vm_num_cpus  = 8
  vm_memory    = 16384
  vm_disk_size = "100G" # newly permitted by the widened validation list

  vm_tags = ["crossplane", "labul"]
}

output "ip" {
  value = module.vm.ip
}

output "vmid" {
  value = module.vm.vmid
}
