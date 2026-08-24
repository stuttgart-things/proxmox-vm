# Non-blocking assertions. A failing `check` emits a warning and lets the plan
# continue — used here for configurations that are legal but almost certainly a
# mistake, where a hard precondition would break someone whose VM already works.

check "uefi_needs_efidisk" {
  assert {
    condition     = lower(var.vm_firmware) != "ovmf" || var.vm_efi_disk_storage != null
    error_message = "vm_firmware is \"ovmf\" but vm_efi_disk_storage is unset: unless the template already carries an EFI vars disk, the guest cannot persist boot entries and OVMF drops to the EFI shell. Set vm_efi_disk_storage (usually the same value as pve_datastore)."
  }
}

check "cloudinit_user_without_password" {
  assert {
    condition     = var.vm_ci_user == null || var.vm_ci_password != null || var.vm_ci_ssh_keys != null
    error_message = "vm_ci_user is set with neither vm_ci_password nor vm_ci_ssh_keys: cloud-init applies its lock_passwd default and LOCKS the account, wiping any password baked into the template. Set one of them."
  }
}

check "efidisk_without_uefi" {
  assert {
    condition     = var.vm_efi_disk_storage == null || lower(var.vm_firmware) == "ovmf"
    error_message = "vm_efi_disk_storage is set but vm_firmware is not \"ovmf\": the EFI vars disk will be allocated and then ignored by seabios."
  }
}

check "iothread_needs_single_controller" {
  assert {
    condition     = var.vm_disk_iothread != true || var.vm_storage_controller == "virtio-scsi-single"
    error_message = "vm_disk_iothread is true but vm_storage_controller is not \"virtio-scsi-single\": Proxmox only honours a per-disk I/O thread on that controller, so on virtio-scsi-pci the setting is accepted and silently ignored."
  }
}

check "cloudinit_settings_without_drive" {
  assert {
    condition = var.vm_cloudinit_datastore != null || alltrue([
      var.vm_ci_user == null,
      var.vm_ci_password == null,
      var.vm_ci_ssh_keys == null,
      var.vm_ci_nameserver == null,
      var.vm_ci_searchdomain == null,
      var.vm_ci_upgrade == null,
    ])
    error_message = "vm_ci_* is set but vm_cloudinit_datastore is not. Proxmox has nowhere to write the generated user-data, so every cloud-init setting is accepted and silently ignored — unless the template already carries a cidata drive AND you declared its slot. Set vm_cloudinit_datastore."
  }
}
