# Exercises each opt-in feature and the guardrails around them.

mock_provider "proxmox" {}

variables {
  pve_cluster_node = "ul-pve02"
  pve_datastore    = "V5010-01-1"
  pve_folder_path  = "stuttgart-things"
  pve_network      = "vmbrvlan"
  vm_name          = "unit-test"
  vm_template      = "ubuntu22"
}

run "cloud_init_is_wired" {
  command = plan

  variables {
    # Required as of the disk -> disks migration: without a cidata drive every
    # field below is accepted and silently ignored.
    vm_cloudinit_datastore = "DD-sthings"
    vm_ci_user             = "sthings"
    vm_ci_password         = "s3cr3t"
    # Throwaway keys generated for this test only.
    vm_ci_ssh_keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPNoF5v3okHuuhNlrDKk1Yqbi+MqHfHaEkWuhQLNcKH/ unit-test-1",
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPmkVKQp8N5obmscwWCoFUFORv0APXAFTW3BqSdCN8Jt unit-test-2",
    ]
    vm_ci_upgrade      = false
    vm_ci_nameserver   = "10.31.101.20 10.31.101.21"
    vm_ci_searchdomain = "labul.sva.de"
    vm_ci_os_type      = "cloud-init"
  }

  assert {
    condition     = proxmox_vm_qemu.proxmox_vm[0].ciuser == "sthings"
    error_message = "ciuser not wired"
  }

  assert {
    condition     = proxmox_vm_qemu.proxmox_vm[0].sshkeys == "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPNoF5v3okHuuhNlrDKk1Yqbi+MqHfHaEkWuhQLNcKH/ unit-test-1\nssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPmkVKQp8N5obmscwWCoFUFORv0APXAFTW3BqSdCN8Jt unit-test-2"
    error_message = "ssh keys must be newline-joined into the single sshkeys string"
  }

  assert {
    condition     = proxmox_vm_qemu.proxmox_vm[0].os_type == "cloud-init"
    error_message = "vm_ci_os_type must map to os_type, distinct from qemu_os"
  }

  assert {
    condition     = proxmox_vm_qemu.proxmox_vm[0].qemu_os == "l26"
    error_message = "vm_os_type must stay on qemu_os and be unaffected by vm_ci_os_type"
  }
}

run "clone_by_vmid" {
  command = plan

  variables {
    vm_template   = null
    vm_clone_id   = 144
    vm_full_clone = true
    vm_id         = 9144
    vm_vlan_tag   = 102
    vm_tags       = ["crossplane", "kind"]
  }

  assert {
    condition     = proxmox_vm_qemu.proxmox_vm[0].clone_id == 144
    error_message = "clone_id not wired"
  }

  assert {
    condition     = proxmox_vm_qemu.proxmox_vm[0].clone == null
    error_message = "clone must be null when cloning by VMID, or the provider sees two sources"
  }

  assert {
    condition     = proxmox_vm_qemu.proxmox_vm[0].vmid == 9144
    error_message = "vmid not wired"
  }

  assert {
    condition     = proxmox_vm_qemu.proxmox_vm[0].network[0].tag == 102
    error_message = "a real vlan tag must pass through untouched"
  }

  assert {
    condition     = proxmox_vm_qemu.proxmox_vm[0].tags == "crossplane,kind"
    error_message = "tags must be comma-joined"
  }
}

run "uefi_emits_efidisk" {
  command = plan

  variables {
    vm_firmware                   = "ovmf"
    vm_efi_disk_storage           = "V5010-01-1"
    vm_efi_disk_pre_enrolled_keys = true
  }

  assert {
    condition     = length(proxmox_vm_qemu.proxmox_vm[0].efidisk) == 1
    error_message = "efidisk block must be emitted when vm_efi_disk_storage is set"
  }

  assert {
    condition     = proxmox_vm_qemu.proxmox_vm[0].efidisk[0].efitype == "4m"
    error_message = "efitype default not applied"
  }
}

run "smbios_emitted_on_either_field" {
  command = plan

  variables {
    vm_smbios_manufacturer = "stuttgart-things"
  }

  assert {
    condition     = length(proxmox_vm_qemu.proxmox_vm[0].smbios) == 1
    error_message = "manufacturer alone must be enough to emit the block"
  }
}

run "bootstrap_created_when_opted_in" {
  command = plan

  variables {
    vm_enable_ssh_provisioner = true
    vm_ssh_user               = "sthings"
    vm_ssh_password           = "s3cr3t"
    vm_count                  = 2
  }

  assert {
    condition     = length(terraform_data.bootstrap) == 2
    error_message = "one bootstrap per VM"
  }
}

# --- guardrails -------------------------------------------------------------

run "both_clone_sources_is_rejected" {
  command = plan

  variables {
    vm_template = "ubuntu22"
    vm_clone_id = 144
  }

  expect_failures = [proxmox_vm_qemu.proxmox_vm]
}

run "no_clone_source_is_rejected" {
  command = plan

  variables {
    vm_template = null
  }

  expect_failures = [proxmox_vm_qemu.proxmox_vm]
}

run "balloon_above_memory_is_rejected" {
  command = plan

  variables {
    vm_memory  = 4096
    vm_balloon = 8192
  }

  expect_failures = [proxmox_vm_qemu.proxmox_vm]
}

run "bootstrap_without_credentials_is_rejected" {
  command = plan

  variables {
    vm_enable_ssh_provisioner = true
    vm_ssh_user               = "sthings"
  }

  expect_failures = [terraform_data.bootstrap]
}

run "bad_vlan_tag_is_rejected" {
  command = plan

  variables {
    vm_vlan_tag = 1
  }

  expect_failures = [var.vm_vlan_tag]
}

run "bad_efitype_is_rejected" {
  command = plan

  variables {
    vm_firmware         = "ovmf"
    vm_efi_disk_storage = "V5010-01-1"
    vm_efi_disk_type    = "8m"
  }

  expect_failures = [var.vm_efi_disk_type]
}

run "reserved_vmid_is_rejected" {
  command = plan

  variables {
    vm_id = 42
  }

  expect_failures = [var.vm_id]
}

# The `check` blocks are advisory at plan time (warning, not error) but are
# surfaced as failures by `terraform test`, which is what makes them testable.

run "uefi_without_efidisk_warns" {
  command = plan

  variables {
    vm_firmware = "ovmf"
  }

  expect_failures = [check.uefi_needs_efidisk]
}

run "ci_user_without_credentials_warns" {
  command = plan

  variables {
    # A datastore is given so that only the intended check fires; without it
    # cloudinit_settings_without_drive would trip as well.
    vm_cloudinit_datastore = "DD-sthings"
    vm_ci_user             = "sthings"
  }

  expect_failures = [check.cloudinit_user_without_password]
}
