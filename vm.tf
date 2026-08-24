locals {
  # Kept verbatim from the original inline expression so existing VMs keep
  # their names: the first VM is bare, every later one gets a 1-based suffix.
  vm_names = [
    for i in range(var.vm_count) :
    i > 0 ? "${var.vm_name}-${i + 1}" : var.vm_name
  ]

  # Every string variable in this module defaults to the bool `false`, which
  # Terraform coerces to "false". Treat that, "" and null alike as "unset".
  # NOTE: `null != "false"` evaluates to true in HCL, so the null case has to
  # be normalised away BEFORE the comparison, not folded into it.
  vm_template_str = var.vm_template == null ? "" : tostring(var.vm_template)
  vm_template_set = local.vm_template_str != "" && local.vm_template_str != "false"

  emit_smbios  = var.vm_smbios_manufacturer != null || var.vm_smbios_product != null
  emit_efidisk = var.vm_efi_disk_storage != null

  # Slot routing for the `disks` block. The bus is the slot name without its
  # trailing index: "virtio0" -> "virtio".
  boot_slot = var.vm_bootdisk
  boot_bus  = replace(var.vm_bootdisk, "/[0-9]+$/", "")

  # null unless a cloud-init datastore was given, which is what keeps the
  # rendering identical to the pre-migration module by default.
  ci_slot = var.vm_cloudinit_datastore == null ? null : var.vm_cloudinit_slot
}

resource "proxmox_vm_qemu" "proxmox_vm" {
  target_node        = var.pve_cluster_node
  pool               = var.pve_folder_path
  start_at_node_boot = var.vm_onboot
  count              = var.vm_count
  name               = local.vm_names[count.index]
  description        = var.vm_notes
  bios               = var.vm_firmware
  ipconfig0          = var.vm_network_address0
  memory             = var.vm_memory
  scsihw             = var.vm_storage_controller
  # `bootdisk` is deliberately NOT set — declaring it produces a PERPETUAL DIFF.
  #
  # The provider DOES write it back (`d.Set("bootdisk", config.BootDisk)`, in
  # both rc07 and rc09), but it writes back an empty string: modern Proxmox no
  # longer returns a legacy `bootdisk` field. It expresses boot order as
  # `boot: order=virtio0;net0` instead — confirmed on live VM 9101, whose
  # config had `boot` and no `bootdisk` at all. So state gets "" while the
  # config insists on "virtio0", and every plan wants to add it again.
  #
  # The attribute is Optional+Computed, so leaving it out is clean, and the
  # real boot order follows from the `disks` layout anyway.
  # var.vm_bootdisk still drives which slot block is emitted below.
  agent   = var.vm_guest_agent
  qemu_os = var.vm_os_type

  # Clone by name (vm_template) or by VMID (vm_clone_id) — never both. The
  # precondition below rejects the ambiguous case rather than letting the
  # provider pick one.
  clone      = var.vm_clone_id == null && local.vm_template_set ? local.vm_template_str : null
  clone_id   = var.vm_clone_id
  full_clone = var.vm_full_clone

  # Optional/Computed upstream, so null here means "let Proxmox assign" and
  # never shows up as a diff.
  vmid = var.vm_id

  tags    = var.vm_tags == null ? null : join(",", var.vm_tags)
  balloon = var.vm_balloon

  # --- cloud-init (all null unless opted in) ---
  os_type      = var.vm_ci_os_type
  ciuser       = var.vm_ci_user
  cipassword   = var.vm_ci_password
  sshkeys      = var.vm_ci_ssh_keys == null ? null : join("\n", var.vm_ci_ssh_keys)
  ciupgrade    = var.vm_ci_upgrade
  nameserver   = var.vm_ci_nameserver
  searchdomain = var.vm_ci_searchdomain

  cpu {
    cores   = var.vm_num_cpus
    sockets = var.vm_num_sockets
    numa    = var.vm_numa
    type    = var.vm_cpu_type
  }

  # ---------------------------------------------------------------------------
  # STORAGE — Telmate's `disks` block (NOT the legacy `disk` block).
  #
  # The two conflict (`"disk": conflicts with disks`), and only `disks` can
  # configure a cloud-init drive. See docs/migration-disks.md for why this
  # module moved, and what it means for existing state.
  #
  # *** THE BLOCK IS AUTHORITATIVE. *** Every slot it does NOT declare is sent
  # to Proxmox with delete=1. In proxmox-api-go that is a no-op on an empty
  # slot and a REMOVAL on an occupied one:
  #
  #   func (storage qemuStorage) mapToApiValues(currentStorage *qemuStorage, …)
  #       if storage.delete {
  #           if currentStorage == nil { return delete }        // empty: no-op
  #           return delete + "," + id.String()                 // occupied: gone
  #
  # The legacy `disk` block behaved identically — it built its request from
  # sdk_Disks_Qemu*DisksDefault(), which marks every slot Delete:true — so this
  # is not a regression introduced here. It IS the reason a template's
  # cloud-init drive used to disappear, which is why every `vm_ci_*` variable
  # looked inert. Declaring `vm_cloudinit_datastore` is what fixes that.
  #
  # Consequence for you: a data disk you added by hand in the Proxmox UI is not
  # declared here and WILL be removed on the next apply.
  #
  # The slot blocks below are generated: Terraform cannot compute a block name,
  # so each supported slot needs its own `dynamic` block gated on a local.
  # Supported boot slots are 0 and 1 of each bus; cloud-init lives on ide0-ide3
  # (Proxmox convention is ide2). To add a slot, extend BOTH the block list
  # below and the vm_bootdisk validation.
  # ---------------------------------------------------------------------------
  # === GENERATED SLOT BLOCKS — see the header comment above ===
  disks {
    dynamic "virtio" {
      for_each = local.boot_bus == "virtio" ? [1] : []
      content {
        dynamic "virtio0" {
          for_each = local.boot_slot == "virtio0" ? [1] : []
          content {
            disk {
              size      = var.vm_disk_size
              storage   = var.pve_datastore
              format    = var.vm_disk_format
              cache     = var.vm_disk_cache
              discard   = var.vm_disk_discard
              backup    = var.vm_disk_backup
              replicate = var.vm_disk_replicate
              iothread  = var.vm_disk_iothread
            }
          }
        }
        dynamic "virtio1" {
          for_each = local.boot_slot == "virtio1" ? [1] : []
          content {
            disk {
              size      = var.vm_disk_size
              storage   = var.pve_datastore
              format    = var.vm_disk_format
              cache     = var.vm_disk_cache
              discard   = var.vm_disk_discard
              backup    = var.vm_disk_backup
              replicate = var.vm_disk_replicate
              iothread  = var.vm_disk_iothread
            }
          }
        }
      }
    }
    dynamic "scsi" {
      for_each = local.boot_bus == "scsi" ? [1] : []
      content {
        dynamic "scsi0" {
          for_each = local.boot_slot == "scsi0" ? [1] : []
          content {
            disk {
              size       = var.vm_disk_size
              storage    = var.pve_datastore
              format     = var.vm_disk_format
              cache      = var.vm_disk_cache
              discard    = var.vm_disk_discard
              backup     = var.vm_disk_backup
              replicate  = var.vm_disk_replicate
              iothread   = var.vm_disk_iothread
              emulatessd = var.vm_disk_emulate_ssd
            }
          }
        }
        dynamic "scsi1" {
          for_each = local.boot_slot == "scsi1" ? [1] : []
          content {
            disk {
              size       = var.vm_disk_size
              storage    = var.pve_datastore
              format     = var.vm_disk_format
              cache      = var.vm_disk_cache
              discard    = var.vm_disk_discard
              backup     = var.vm_disk_backup
              replicate  = var.vm_disk_replicate
              iothread   = var.vm_disk_iothread
              emulatessd = var.vm_disk_emulate_ssd
            }
          }
        }
      }
    }
    dynamic "sata" {
      for_each = local.boot_bus == "sata" ? [1] : []
      content {
        dynamic "sata0" {
          for_each = local.boot_slot == "sata0" ? [1] : []
          content {
            disk {
              size       = var.vm_disk_size
              storage    = var.pve_datastore
              format     = var.vm_disk_format
              cache      = var.vm_disk_cache
              discard    = var.vm_disk_discard
              backup     = var.vm_disk_backup
              replicate  = var.vm_disk_replicate
              emulatessd = var.vm_disk_emulate_ssd
            }
          }
        }
        dynamic "sata1" {
          for_each = local.boot_slot == "sata1" ? [1] : []
          content {
            disk {
              size       = var.vm_disk_size
              storage    = var.pve_datastore
              format     = var.vm_disk_format
              cache      = var.vm_disk_cache
              discard    = var.vm_disk_discard
              backup     = var.vm_disk_backup
              replicate  = var.vm_disk_replicate
              emulatessd = var.vm_disk_emulate_ssd
            }
          }
        }
      }
    }
    dynamic "ide" {
      for_each = local.boot_bus == "ide" || local.ci_slot != null ? [1] : []
      content {
        dynamic "ide0" {
          for_each = local.boot_slot == "ide0" || local.ci_slot == "ide0" ? [1] : []
          content {
            dynamic "disk" {
              for_each = local.boot_slot == "ide0" ? [1] : []
              content {
                size       = var.vm_disk_size
                storage    = var.pve_datastore
                format     = var.vm_disk_format
                cache      = var.vm_disk_cache
                discard    = var.vm_disk_discard
                backup     = var.vm_disk_backup
                replicate  = var.vm_disk_replicate
                emulatessd = var.vm_disk_emulate_ssd
              }
            }
            dynamic "cloudinit" {
              for_each = local.ci_slot == "ide0" ? [1] : []
              content {
                storage = var.vm_cloudinit_datastore
              }
            }
          }
        }
        dynamic "ide1" {
          for_each = local.boot_slot == "ide1" || local.ci_slot == "ide1" ? [1] : []
          content {
            dynamic "disk" {
              for_each = local.boot_slot == "ide1" ? [1] : []
              content {
                size       = var.vm_disk_size
                storage    = var.pve_datastore
                format     = var.vm_disk_format
                cache      = var.vm_disk_cache
                discard    = var.vm_disk_discard
                backup     = var.vm_disk_backup
                replicate  = var.vm_disk_replicate
                emulatessd = var.vm_disk_emulate_ssd
              }
            }
            dynamic "cloudinit" {
              for_each = local.ci_slot == "ide1" ? [1] : []
              content {
                storage = var.vm_cloudinit_datastore
              }
            }
          }
        }
        dynamic "ide2" {
          for_each = local.ci_slot == "ide2" ? [1] : []
          content {
            dynamic "cloudinit" {
              for_each = local.ci_slot == "ide2" ? [1] : []
              content {
                storage = var.vm_cloudinit_datastore
              }
            }
          }
        }
        dynamic "ide3" {
          for_each = local.ci_slot == "ide3" ? [1] : []
          content {
            dynamic "cloudinit" {
              for_each = local.ci_slot == "ide3" ? [1] : []
              content {
                storage = var.vm_cloudinit_datastore
              }
            }
          }
        }
      }
    }
  }

  network {
    id      = 0
    model   = var.vm_network_type
    bridge  = var.pve_network
    macaddr = var.vm_macaddr
    # -1 is this module's "untagged" sentinel and must NOT reach the provider:
    # Telmate v3 validates `tag >= 0` and fails the plan with
    #   tag must be equal or greater than 0, got: -1
    # Omitting the attribute is what actually means "no VLAN tag".
    tag      = var.vm_vlan_tag == -1 ? null : var.vm_vlan_tag
    firewall = var.vm_network_firewall
    mtu      = var.vm_network_mtu
  }

  dynamic "smbios" {
    for_each = local.emit_smbios ? [1] : []
    content {
      manufacturer = var.vm_smbios_manufacturer
      product      = var.vm_smbios_product
    }
  }

  dynamic "efidisk" {
    for_each = local.emit_efidisk ? [1] : []
    content {
      storage           = var.vm_efi_disk_storage
      efitype           = var.vm_efi_disk_type
      pre_enrolled_keys = var.vm_efi_disk_pre_enrolled_keys
    }
  }

  lifecycle {
    # NOTE: `ignore_changes` only accepts literals, so this cannot be made
    # configurable. Consequence: vm_vlan_tag, vm_macaddr, vm_network_firewall
    # and vm_network_mtu take effect on CREATE ONLY. Changing any of them on a
    # live VM is silently ignored — adjust it in Proxmox, or taint the VM.
    ignore_changes = [
      network,
      # Provider noise, not config: Telmate reads back a startup_shutdown block
      # of -1 defaults that this module never declares, so every plan wants to
      # remove it. Confirmed on a live VM (LabUL 9101).
      startup_shutdown,
    ]

    precondition {
      condition     = !(var.vm_clone_id != null && local.vm_template_set)
      error_message = "Set either vm_template (clone by name) or vm_clone_id (clone by VMID), not both."
    }

    precondition {
      condition     = var.vm_clone_id != null || local.vm_template_set
      error_message = "No clone source: set vm_template (by name) or vm_clone_id (by VMID)."
    }

    precondition {
      condition     = var.vm_balloon == null || var.vm_balloon <= var.vm_memory
      error_message = "vm_balloon must not exceed vm_memory."
    }

    precondition {
      condition     = local.ci_slot == null || local.ci_slot != local.boot_slot
      error_message = "vm_cloudinit_slot collides with vm_bootdisk: the boot disk and the cloud-init drive cannot share a slot."
    }

    precondition {
      condition     = local.boot_bus != "virtio" || var.vm_disk_emulate_ssd == null
      error_message = "vm_disk_emulate_ssd is not supported on the virtio bus (no SSD emulation there). Use a scsi/sata/ide boot slot, or leave it unset."
    }

    precondition {
      condition     = contains(["scsi", "virtio"], local.boot_bus) || var.vm_disk_iothread == null
      error_message = "vm_disk_iothread is only available on the scsi and virtio buses. Move the boot disk to one of them, or leave it unset."
    }
  }
}

# The legacy post-create SSH bootstrap, opt-in via vm_enable_ssh_provisioner.
#
# It lives in its own resource rather than inline in proxmox_vm_qemu because a
# provisioner cannot be made conditional. `terraform_data` is a core resource
# (Terraform >= 1.4), so this adds no provider dependency.
#
# Existing state is unaffected: with the flag false no instance is created, and
# provisioners are not tracked as resource attributes, so moving the block out
# of proxmox_vm_qemu produces no diff on already-managed VMs.
resource "terraform_data" "bootstrap" {
  count = var.vm_enable_ssh_provisioner ? var.vm_count : 0

  # Re-run only when the VM behind it is actually replaced.
  triggers_replace = [
    proxmox_vm_qemu.proxmox_vm[count.index].id,
  ]

  lifecycle {
    precondition {
      condition     = var.vm_ssh_user != ""
      error_message = "vm_enable_ssh_provisioner requires vm_ssh_user."
    }

    precondition {
      condition     = var.vm_ssh_password != "" || var.vm_ssh_private_key != null
      error_message = "vm_enable_ssh_provisioner requires vm_ssh_password or vm_ssh_private_key."
    }

    precondition {
      condition     = var.vm_guest_agent == 1
      error_message = "vm_enable_ssh_provisioner requires vm_guest_agent = 1: without the agent Proxmox never reports an IP to connect to."
    }
  }

  connection {
    type        = "ssh"
    host        = proxmox_vm_qemu.proxmox_vm[count.index].default_ipv4_address
    user        = var.vm_ssh_user
    password    = var.vm_ssh_password
    private_key = var.vm_ssh_private_key
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [
      "sudo echo '${local.vm_names[count.index]}' | sudo tee /etc/hostname",
      "sudo systemd-machine-id-setup",
      "sudo shutdown -r +0"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'wait for reboot'"
    ]
  }
}
