# ============================================================================
# 01 — MINIMAL
#
# The smallest working call: clone a template by name onto a node, take a DHCP
# lease, done. Every opt-in feature stays off, so this renders exactly what the
# module rendered before they existed.
#
# What you still need in the guest: the QEMU guest agent, or `output.ip` stays
# empty because Proxmox has no way to report the lease back.
# ============================================================================

module "vm" {
  source = "../../"

  pve_api_url        = var.pve_api_url
  pve_api_user       = var.pve_api_user
  pve_api_password   = var.pve_api_password
  pve_api_tls_verify = var.pve_api_tls_verify

  pve_cluster_node = "sthings-pve1"
  pve_datastore    = "datastore"
  pve_folder_path  = "stuttgart-things"
  pve_network      = "vmbr101"

  # NOTE: "ubuntu22" is a PLACEHOLDER. Query your cluster for real template
  # names/VMIDs (docs/proxmox-api-discovery.md) — in LabUL no such template
  # exists. examples/09-labul-smoketest has verified values.
  vm_name     = "minimal"
  vm_notes    = "created by terraform"
  vm_template = "ubuntu22"
}

output "ip" {
  value = module.vm.ip
}
