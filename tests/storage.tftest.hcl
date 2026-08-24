# The disk -> disks migration: cloud-init drive, slot routing, and the
# per-bus attribute differences Telmate exposes.

mock_provider "proxmox" {}

variables {
  pve_cluster_node = "ul-pve11"
  pve_datastore    = "V5010-01-1"
  pve_folder_path  = "stuttgart-things"
  pve_network      = "vmbrvlan"
  vm_name          = "unit-test"
  vm_clone_id      = 211
  vm_template      = null
}

run "cloudinit_drive_is_emitted" {
  command = plan

  variables {
    vm_cloudinit_datastore = "DD-sthings"
  }

  assert {
    condition     = proxmox_vm_qemu.proxmox_vm[0].disks[0].ide[0].ide2[0].cloudinit[0].storage == "DD-sthings"
    error_message = "the cidata drive must land on ide2 by default"
  }

  assert {
    condition     = proxmox_vm_qemu.proxmox_vm[0].disks[0].virtio[0].virtio0[0].disk[0].storage == "V5010-01-1"
    error_message = "the boot disk stays on its own datastore, separate from the cidata drive"
  }

  assert {
    condition     = length(proxmox_vm_qemu.proxmox_vm[0].disks[0].ide[0].ide0) == 0
    error_message = "only the configured cloud-init slot may be declared"
  }
}

run "cloudinit_slot_is_configurable" {
  command = plan

  variables {
    vm_cloudinit_datastore = "DD-sthings"
    vm_cloudinit_slot      = "ide3"
  }

  assert {
    condition     = proxmox_vm_qemu.proxmox_vm[0].disks[0].ide[0].ide3[0].cloudinit[0].storage == "DD-sthings"
    error_message = "ide3 must be honoured"
  }

  assert {
    condition     = length(proxmox_vm_qemu.proxmox_vm[0].disks[0].ide[0].ide2) == 0
    error_message = "ide2 must not be declared when the drive was moved to ide3"
  }
}

run "boot_disk_and_cloudinit_share_the_ide_bus" {
  command = plan

  variables {
    vm_bootdisk            = "ide0"
    vm_cloudinit_datastore = "DD-sthings"
  }

  assert {
    condition     = proxmox_vm_qemu.proxmox_vm[0].disks[0].ide[0].ide0[0].disk[0].size == "32G"
    error_message = "boot disk on ide0"
  }

  assert {
    condition     = proxmox_vm_qemu.proxmox_vm[0].disks[0].ide[0].ide2[0].cloudinit[0].storage == "DD-sthings"
    error_message = "cidata drive on ide2, on the same bus"
  }

  assert {
    condition     = length(proxmox_vm_qemu.proxmox_vm[0].disks[0].ide[0].ide0[0].cloudinit) == 0
    error_message = "ide0 carries a disk, not a cloudinit drive"
  }
}

run "sata_gets_emulatessd_but_not_iothread" {
  command = plan

  variables {
    vm_bootdisk         = "sata0"
    vm_disk_emulate_ssd = true
  }

  assert {
    condition     = proxmox_vm_qemu.proxmox_vm[0].disks[0].sata[0].sata0[0].disk[0].emulatessd == true
    error_message = "sata supports emulatessd"
  }
}

run "disk_tuning_passes_through" {
  command = plan

  variables {
    vm_disk_format    = "raw"
    vm_disk_cache     = "writeback"
    vm_disk_discard   = true
    vm_disk_backup    = false
    vm_disk_replicate = false
  }

  assert {
    condition = alltrue([
      proxmox_vm_qemu.proxmox_vm[0].disks[0].virtio[0].virtio0[0].disk[0].format == "raw",
      proxmox_vm_qemu.proxmox_vm[0].disks[0].virtio[0].virtio0[0].disk[0].cache == "writeback",
      proxmox_vm_qemu.proxmox_vm[0].disks[0].virtio[0].virtio0[0].disk[0].discard == true,
      proxmox_vm_qemu.proxmox_vm[0].disks[0].virtio[0].virtio0[0].disk[0].backup == false,
      proxmox_vm_qemu.proxmox_vm[0].disks[0].virtio[0].virtio0[0].disk[0].replicate == false,
    ])
    error_message = "disk tuning attributes must reach the boot slot"
  }
}

# --- guardrails -------------------------------------------------------------

run "emulatessd_on_virtio_is_rejected" {
  command = plan

  variables {
    vm_bootdisk         = "virtio0"
    vm_disk_emulate_ssd = true
  }

  expect_failures = [proxmox_vm_qemu.proxmox_vm]
}

run "iothread_on_sata_is_rejected" {
  command = plan

  variables {
    vm_bootdisk = "sata0"
    # virtio-scsi-single so only the bus precondition fires, not the
    # controller check block.
    vm_storage_controller = "virtio-scsi-single"
    vm_disk_iothread      = true
  }

  expect_failures = [proxmox_vm_qemu.proxmox_vm]
}

run "cloudinit_slot_collision_is_rejected" {
  command = plan

  variables {
    vm_bootdisk            = "ide0"
    vm_cloudinit_datastore = "DD-sthings"
    vm_cloudinit_slot      = "ide0"
  }

  expect_failures = [proxmox_vm_qemu.proxmox_vm]
}

run "unsupported_boot_slot_is_rejected" {
  command = plan

  variables {
    vm_bootdisk = "virtio7"
  }

  expect_failures = [var.vm_bootdisk]
}

run "bad_cloudinit_slot_is_rejected" {
  command = plan

  variables {
    vm_cloudinit_datastore = "DD-sthings"
    vm_cloudinit_slot      = "scsi1"
  }

  expect_failures = [var.vm_cloudinit_slot]
}

run "ci_settings_without_drive_warns" {
  command = plan

  variables {
    vm_ci_user     = "sthings"
    vm_ci_password = "s3cr3t"
  }

  expect_failures = [check.cloudinit_settings_without_drive]
}

run "iothread_without_single_controller_warns" {
  command = plan

  variables {
    vm_disk_iothread = true
  }

  expect_failures = [check.iothread_needs_single_controller]
}
