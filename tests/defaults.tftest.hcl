# Verifies the central promise of the opt-in features: with none of them set,
# the resource renders exactly as it did before they existed.

mock_provider "proxmox" {}

variables {
  pve_cluster_node = "sthings-pve1"
  pve_datastore    = "datastore"
  pve_folder_path  = "stuttgart-things"
  pve_network      = "vmbr101"
  vm_name          = "unit-test"
  vm_template      = "ubuntu22"
}

run "defaults_render_unchanged" {
  command = plan

  assert {
    condition     = proxmox_vm_qemu.proxmox_vm[0].clone == "ubuntu22"
    error_message = "clone must fall back to vm_template when vm_clone_id is unset"
  }

  assert {
    condition     = proxmox_vm_qemu.proxmox_vm[0].clone_id == null
    error_message = "clone_id must stay null by default"
  }

  assert {
    condition     = proxmox_vm_qemu.proxmox_vm[0].full_clone == null
    error_message = "full_clone must stay null so the provider default applies"
  }

  assert {
    condition     = proxmox_vm_qemu.proxmox_vm[0].name == "unit-test"
    error_message = "the first VM keeps the bare name"
  }

  assert {
    condition = alltrue([
      proxmox_vm_qemu.proxmox_vm[0].ciuser == null,
      proxmox_vm_qemu.proxmox_vm[0].cipassword == null,
      proxmox_vm_qemu.proxmox_vm[0].sshkeys == null,
      proxmox_vm_qemu.proxmox_vm[0].ciupgrade == null,
      proxmox_vm_qemu.proxmox_vm[0].nameserver == null,
      proxmox_vm_qemu.proxmox_vm[0].searchdomain == null,
      proxmox_vm_qemu.proxmox_vm[0].os_type == null,
      proxmox_vm_qemu.proxmox_vm[0].tags == null,
      proxmox_vm_qemu.proxmox_vm[0].balloon == null,
    ])
    error_message = "no cloud-init or identity extra may be emitted by default"
  }

  assert {
    condition     = length(proxmox_vm_qemu.proxmox_vm[0].smbios) == 0
    error_message = "no smbios block by default"
  }

  assert {
    condition     = length(proxmox_vm_qemu.proxmox_vm[0].efidisk) == 0
    error_message = "no efidisk block by default"
  }

  assert {
    condition     = length(terraform_data.bootstrap) == 0
    error_message = "the SSH bootstrap must not be created unless opted in"
  }

  assert {
    condition     = proxmox_vm_qemu.proxmox_vm[0].network[0].tag == null
    error_message = "the -1 sentinel must be translated to null, not passed through to the provider"
  }
}

run "multi_vm_naming_is_unchanged" {
  command = plan

  variables {
    vm_count = 3
  }

  assert {
    condition = alltrue([
      proxmox_vm_qemu.proxmox_vm[0].name == "unit-test",
      proxmox_vm_qemu.proxmox_vm[1].name == "unit-test-2",
      proxmox_vm_qemu.proxmox_vm[2].name == "unit-test-3",
    ])
    error_message = "count-based naming must match the pre-refactor expression"
  }
}

run "hundred_gig_disk_is_now_accepted" {
  command = plan

  variables {
    vm_disk_size = "100G"
  }

  assert {
    condition     = proxmox_vm_qemu.proxmox_vm[0].disks[0].virtio[0].virtio0[0].disk[0].size == "100G"
    error_message = "100G must pass validation and land on the boot slot"
  }
}

run "disks_block_replaces_legacy_disk" {
  command = plan

  assert {
    condition     = length(proxmox_vm_qemu.proxmox_vm[0].disk) == 0
    error_message = "the legacy disk block must not be emitted — it conflicts with disks"
  }

  assert {
    condition     = length(proxmox_vm_qemu.proxmox_vm[0].disks) == 1
    error_message = "exactly one disks block"
  }

  assert {
    condition = alltrue([
      proxmox_vm_qemu.proxmox_vm[0].disks[0].virtio[0].virtio0[0].disk[0].size == "32G",
      proxmox_vm_qemu.proxmox_vm[0].disks[0].virtio[0].virtio0[0].disk[0].storage == "datastore",
    ])
    error_message = "the boot disk must land on virtio0 with the module's size and datastore"
  }

  assert {
    condition     = length(proxmox_vm_qemu.proxmox_vm[0].disks[0].virtio[0].virtio1) == 0
    error_message = "only the configured boot slot may be declared"
  }
}

run "no_cloudinit_drive_by_default" {
  command = plan

  # The whole point of the default: rendering stays identical to the
  # pre-migration module, so the disk-block migration is a semantic no-op for
  # anyone who does not opt into cloud-init.
  assert {
    condition     = length(proxmox_vm_qemu.proxmox_vm[0].disks[0].ide) == 0
    error_message = "no ide bus, and therefore no cidata drive, unless vm_cloudinit_datastore is set"
  }
}

run "boot_disk_follows_the_bus" {
  command = plan

  variables {
    vm_bootdisk           = "scsi0"
    vm_storage_controller = "virtio-scsi-single"
    vm_disk_emulate_ssd   = true
    vm_disk_iothread      = true
  }

  assert {
    condition     = length(proxmox_vm_qemu.proxmox_vm[0].disks[0].virtio) == 0
    error_message = "the virtio bus must not be emitted for a scsi boot slot"
  }

  assert {
    condition = alltrue([
      proxmox_vm_qemu.proxmox_vm[0].disks[0].scsi[0].scsi0[0].disk[0].size == "32G",
      proxmox_vm_qemu.proxmox_vm[0].disks[0].scsi[0].scsi0[0].disk[0].emulatessd == true,
      proxmox_vm_qemu.proxmox_vm[0].disks[0].scsi[0].scsi0[0].disk[0].iothread == true,
    ])
    error_message = "scsi carries both emulatessd and iothread"
  }
}
