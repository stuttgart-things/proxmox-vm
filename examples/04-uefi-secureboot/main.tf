# ============================================================================
# 04 — UEFI / OVMF
#
# Switching vm_firmware to "ovmf" is not enough on its own: without an EFI vars
# disk the guest has nowhere to persist boot entries and OVMF drops straight to
# the EFI shell on second boot. The module emits a `check` warning if you set
# one without the other, in either direction.
#
# vm_efi_disk_pre_enrolled_keys enrols the Microsoft Secure Boot keys. Leave it
# false unless the guest is genuinely signed — enrolled keys refuse to boot an
# unsigned kernel or an out-of-tree module (nvidia, zfs, virtualbox).
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

  vm_name     = "uefi-demo"
  vm_template = "ubuntu24-uefi"

  vm_firmware = "ovmf"

  # --- opt-in: EFI vars disk ---
  vm_efi_disk_storage           = "datastore" # usually the same as pve_datastore
  vm_efi_disk_type              = "4m"
  vm_efi_disk_pre_enrolled_keys = false

  # OVMF wants a modern machine type and a q35-friendly controller.
  vm_storage_controller = "virtio-scsi-single"
}

output "ip" {
  value = module.vm.ip
}
