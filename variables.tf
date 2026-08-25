variable "pve_cluster_node" {
  default     = false
  type        = string
  description = "name of proxmox cluster node"
}

variable "pve_folder_path" {
  default     = false
  type        = string
  description = "target (vm) folder path of proxmox virtual machine"
}

variable "pve_datastore" {
  default     = false
  type        = string
  description = "name of proxmox datastore"
}

variable "pve_network" {
  default     = false
  type        = string
  description = "name of proxmox network"
}

variable "vm_numa" {
  default     = true
  type        = bool
  description = "enable numa for vm"
}

variable "vm_onboot" {
  default     = true
  type        = bool
  description = "whether to have the VM startup after the PVE node starts"
}

variable "vm_firmware" {
  default     = "seabios"
  type        = string
  description = "the firmware interface to use on the virtual machine. Can be one of bios or EFI. Default: bios"
}

variable "vm_os_type" {
  default     = "l26"
  type        = string
  description = "the type of OS in the guest to allow Proxmox to enable optimizations for the appropriate guest OS"
}

variable "vm_count" {
  default     = 1
  type        = number
  description = "count of vms"

  validation {
    condition     = var.vm_count >= 1 && var.vm_count <= 5 && floor(var.vm_count) == var.vm_count
    error_message = "Accepted values: 1-5."
  }

}

variable "vm_name" {
  default     = false
  type        = string
  description = "name of proxmox virtual machine"
}

variable "vm_guest_agent" {
  default     = 1
  type        = number
  description = "QEMU Guest Agent configuration set 0 to disable 1 to enable"
}

variable "vm_notes" {
  default     = false
  type        = string
  description = "notes of proxmox virtual machine shwon in UI"
}

variable "vm_template" {
  default     = false
  type        = string
  description = "name of proxmox virtual machine template"
}

variable "vm_num_cpus" {
  default     = 2
  type        = number
  description = "amount of cpus of the vm"

  validation {
    condition     = contains([2, 4, 6, 8, 10, 12, 16], var.vm_num_cpus)
    error_message = "Valid values for vm_num_cpus are (2, 4, 6, 8, 10, 12, 16)"
  }

}

variable "vm_num_sockets" {
  default     = 1
  type        = number
  description = "amount of sockets of the vm"
}

variable "vm_memory" {
  default     = 4096
  type        = number
  description = "amount of memory of the vm"

  validation {
    condition     = contains([1024, 2048, 4096, 8192, 12288, 16384, 20480, 24576], var.vm_memory)
    error_message = "Valid values for vm_memory are (1024, 2048, 4096, 8192, 12288, 16384, 20480, 24576)"
  }
}

variable "vm_disk_size" {
  default     = "32G"
  description = "size of disk"
  type        = string

  validation {
    condition     = contains(["20G", "32G", "48G", "64G", "80G", "96G", "100G", "128G", "160G", "196G", "200G", "256G", "320G", "512G", "1024G"], var.vm_disk_size)
    error_message = "Valid values for vm_disk_size are (20G, 32G, 48G, 64G, 80G, 96G, 100G, 128G, 160G, 196G, 200G, 256G, 320G, 512G, 1024G)"
  }

}

variable "vm_bootdisk" {
  default     = "virtio0"
  type        = string
  description = <<-EOT
    Slot the root disk is attached to. This now selects a nested block inside
    Telmate's `disks` block, so it is no longer a free-form string — only the
    slots the module generates a block for are accepted.

    Match it to the TEMPLATE's root disk slot. The stuttgart-things `sthings-u26`
    image is on `virtio0`, not `scsi0`; a mismatch means the module declares a
    slot the VM does not have while leaving the real one undeclared — and an
    undeclared slot is deleted.

    To support a slot beyond 0 and 1 of each bus, extend both this validation
    and the generated block list in vm.tf.
  EOT

  validation {
    condition = contains([
      "virtio0", "virtio1",
      "scsi0", "scsi1",
      "sata0", "sata1",
      "ide0", "ide1",
    ], var.vm_bootdisk)
    error_message = "Valid values for vm_bootdisk are virtio0/1, scsi0/1, sata0/1, ide0/1."
  }
}

variable "vm_storage_controller" {
  default     = "virtio-scsi-pci"
  type        = string
  description = "storage controller to emulate"
}

variable "vm_network_type" {
  default     = "virtio"
  type        = string
  description = "network card type"
}

variable "vm_ssh_user" {
  default     = ""
  type        = string
  description = "Username of VM"
}

variable "vm_ssh_password" {
  default     = ""
  type        = string
  description = "Password of VM user"
}

variable "vm_network_address0" {
  default     = "ip=dhcp"
  type        = string
  description = "The first IP address to assign to the guest (set to ip=dhcp to get a ip output)"
}

variable "vm_macaddr" {
  default     = null
  type        = string
  description = "Mac address of desired vm"
}

variable "vm_vlan_tag" {
  default     = -1
  type        = number
  description = <<-EOT
    VLAN tag for the network interface (e.g. on the VLAN-aware bridge
    `vmbrvlan`). -1 means untagged, and is a MODULE-LEVEL sentinel only: the
    attribute is omitted entirely rather than sent as -1, which Telmate v3
    rejects with "tag must be equal or greater than 0".

    CREATE ONLY — the resource ignores changes to the whole `network` block,
    so re-tagging a live VM here is silently ignored.
  EOT

  validation {
    condition     = var.vm_vlan_tag == -1 || (var.vm_vlan_tag >= 2 && var.vm_vlan_tag <= 4094)
    error_message = "Valid values for vm_vlan_tag are -1 (untagged) or 2-4094."
  }
}

variable "pve_api_url" {
  default     = false
  type        = string
  description = "url of proxmox api"
}

variable "pve_api_user" {
  default     = false
  type        = string
  description = "username of proxmox api user"
}

variable "pve_api_password" {
  default     = false
  type        = string
  description = "password of proxmox api user"
}

variable "pve_api_tls_verify" {
  default     = true
  type        = bool
  description = <<-EOT
    *** THE NAME IS INVERTED — READ THIS BEFORE SETTING IT ***

    Wired straight to the provider's `pm_tls_insecure`, so despite reading like
    "verify", true means DO NOT VERIFY:

      true  (default) -> TLS certificate checking is DISABLED
      false           -> the Proxmox certificate must validate

    The default therefore skips verification, which is what most Proxmox
    installs need (self-signed cluster certs) but is not what the name implies.
    Set it to false anywhere the API is fronted by a properly signed cert.

    Kept as-is because renaming it would break every existing caller; see the
    README "Known warts" section.
  EOT
}

# =============================================================================
# OPT-IN FEATURES
#
# Every variable below defaults to null / false, which renders the resource
# BYTE-IDENTICAL to a module without them. Nothing here changes an existing
# VM until you explicitly set it.
#
# EXCEPTION: vm_enable_ssh_provisioner. See its comment.
# =============================================================================

# -----------------------------------------------------------------------------
# Clone source
# -----------------------------------------------------------------------------

variable "vm_clone_id" {
  default     = null
  type        = number
  description = <<-EOT
    VMID of the template to clone. Opt-in alternative to `vm_template`, which
    clones by NAME. Use this when template names are ambiguous across the
    cluster, or when you track templates by ID (as the Crossplane
    NativeProxmoxVM XR's `vm.templateVmId` does).

    Mutually exclusive with `vm_template` — setting both fails a precondition.

    FORCES REPLACEMENT: switching an existing VM between `vm_template` and
    `vm_clone_id`, or changing either value, destroys and recreates the VM.
  EOT
}

variable "vm_full_clone" {
  default     = null
  type        = bool
  description = <<-EOT
    Full clone (true) vs linked clone (false). Unset leaves the provider
    default (full clone). A linked clone is fast and thin but pins the VM to
    the template's datastore forever and cannot outlive the template.

    FORCES REPLACEMENT on change.
  EOT
}

# -----------------------------------------------------------------------------
# Identity
# -----------------------------------------------------------------------------

variable "vm_id" {
  default     = null
  type        = number
  description = <<-EOT
    Explicit VMID for the new VM. Unset lets Proxmox assign the next free one
    (the attribute is Computed, so leaving it null never produces a diff).

    Only set this on a VM that does not exist yet.
  EOT

  validation {
    condition     = var.vm_id == null || (var.vm_id >= 100 && var.vm_id <= 999999999)
    error_message = "vm_id must be between 100 and 999999999 (Proxmox reserves 0-99)."
  }
}

variable "vm_tags" {
  default     = null
  type        = list(string)
  description = <<-EOT
    Proxmox tags shown in the UI and usable as API selectors. Joined with ","
    for the provider. Proxmox lowercases tags and reorders them alphabetically
    server-side; pass them lowercase and sorted to avoid a perpetual diff.
  EOT
}

# -----------------------------------------------------------------------------
# CPU / memory
# -----------------------------------------------------------------------------

variable "vm_cpu_type" {
  default     = null
  type        = string
  description = <<-EOT
    CPU model exposed to the guest, e.g. "host", "x86-64-v2-AES", "kvm64".
    Unset leaves the provider default. "host" gives the best performance but
    blocks live migration to a node with a different CPU.
  EOT
}

variable "vm_balloon" {
  default     = null
  type        = number
  description = <<-EOT
    Minimum memory in MiB for the balloon driver. Unset disables ballooning
    (the VM keeps `vm_memory` pinned). Set BELOW `vm_memory` to let the host
    reclaim memory. 0 explicitly disables the balloon device.
  EOT
}

# -----------------------------------------------------------------------------
# Cloud-init
#
# All of these require the template to actually run cloud-init AND to have a
# cloud-init drive. Templates built without one (the stuttgart-things Packer
# images among them) ignore every field here silently.
# -----------------------------------------------------------------------------

variable "vm_ci_user" {
  default     = null
  type        = string
  description = "Default cloud-init user (`ciuser`). Unset keeps whatever the template baked in."
}

variable "vm_ci_password" {
  default     = null
  type        = string
  sensitive   = true
  description = <<-EOT
    Password for `vm_ci_user` (`cipassword`).

    Set this whenever the template runs cloud-init. With `ciuser` set and no
    password, cloud-init applies its `lock_passwd` default and LOCKS the
    account (`passwd -S` reports `L`) — wiping the password baked in at build
    time and breaking any password-based Ansible run afterwards.

    Proxmox returns this field hashed, so the provider cannot diff it: changing
    it here does NOT rotate the password on a live VM.
  EOT
}

variable "vm_ci_ssh_keys" {
  default     = null
  type        = list(string)
  description = <<-EOT
    Public keys authorized for `vm_ci_user` (`sshkeys`). Given as a list, one
    full key per element ("ssh-ed25519 AAAA... comment"); the module joins them
    with newlines for the provider.
  EOT
}

variable "vm_ci_upgrade" {
  default     = null
  type        = bool
  description = <<-EOT
    Run a package upgrade on first boot (`ciupgrade`). Unset leaves the
    provider default. Costs minutes of boot time and needs working egress —
    leave it off when an Ansible run does the patching anyway.
  EOT
}

variable "vm_ci_nameserver" {
  default     = null
  type        = string
  description = <<-EOT
    DNS servers for cloud-init (`nameserver`). Proxmox takes a SPACE-separated
    list in one string, e.g. "10.0.0.1 10.0.0.2". Unset inherits the host node's
    resolver settings.
  EOT
}

variable "vm_ci_searchdomain" {
  default     = null
  type        = string
  description = "DNS search domain for cloud-init (`searchdomain`)."
}

variable "vm_ci_os_type" {
  default     = null
  type        = string
  description = <<-EOT
    Telmate's `os_type`, which selects the PROVISIONING flavour — "cloud-init",
    "ubuntu", "centos". NOT the same field as `vm_os_type`, which maps to
    `qemu_os` and only tells Proxmox which guest optimizations to enable.

    Set to "cloud-init" when driving the VM through the cloud-init variables
    above instead of the SSH provisioner.
  EOT
}

# -----------------------------------------------------------------------------
# Network extras
# -----------------------------------------------------------------------------

variable "vm_network_firewall" {
  default     = null
  type        = bool
  description = "Enable the Proxmox firewall on the NIC. Unset leaves the provider default."
}

variable "vm_network_mtu" {
  default     = null
  type        = number
  description = <<-EOT
    NIC MTU. Unset leaves the provider default. 1 means "inherit from the
    bridge", which is what you usually want on a VXLAN/overlay bridge.
  EOT
}

# -----------------------------------------------------------------------------
# SMBIOS
# -----------------------------------------------------------------------------

variable "vm_smbios_manufacturer" {
  default     = null
  type        = string
  description = <<-EOT
    SMBIOS manufacturer string. Setting either this or `vm_smbios_product`
    emits an smbios block; leaving both null emits none.

    WHY YOU MIGHT WANT THIS: the LabUL Proxmox nodes run PegaProx's "SMBIOS
    Auto-Configurator", a systemd service that stamps every NEW VM that has no
    SMBIOS keys of its own. Emitting our own block makes PegaProx skip the VM —
    its needs_smbios_update() leaves any VM that already has SMBIOS keys alone.

    FORCES REPLACEMENT on change.
  EOT
}

variable "vm_smbios_product" {
  default     = null
  type        = string
  description = "SMBIOS product string. See `vm_smbios_manufacturer`."
}

# -----------------------------------------------------------------------------
# UEFI
# -----------------------------------------------------------------------------

variable "vm_efi_disk_storage" {
  default     = null
  type        = string
  description = <<-EOT
    Datastore for the EFI vars disk. REQUIRED when `vm_firmware = "ovmf"` on a
    VM that does not already carry one — without it the guest has nowhere to
    persist boot entries and OVMF drops to the EFI shell. Usually the same
    value as `pve_datastore`.

    Leave null for seabios (the default), which needs no EFI disk.
  EOT
}

variable "vm_efi_disk_type" {
  default     = "4m"
  type        = string
  description = "EFI vars disk size/type — \"2m\" (legacy) or \"4m\". Only used when `vm_efi_disk_storage` is set."

  validation {
    condition     = contains(["2m", "4m"], var.vm_efi_disk_type)
    error_message = "Valid values for vm_efi_disk_type are (2m, 4m)."
  }
}

variable "vm_efi_disk_pre_enrolled_keys" {
  default     = false
  type        = bool
  description = <<-EOT
    Pre-enroll the Microsoft Secure Boot keys in the EFI vars disk. Only used
    when `vm_efi_disk_storage` is set. Leave false unless the guest is actually
    signed for Secure Boot — enrolled keys will refuse to boot an unsigned
    kernel or an out-of-tree module.
  EOT
}

# -----------------------------------------------------------------------------
# SSH bootstrap provisioner
# -----------------------------------------------------------------------------

variable "vm_enable_ssh_provisioner" {
  default     = false
  type        = bool
  description = <<-EOT
    Run the legacy post-create SSH bootstrap: write /etc/hostname, regenerate
    the machine-id, reboot, wait.

    *** BEHAVIOUR CHANGE ***
    This bootstrap used to be unconditional. It now defaults to FALSE, so a
    caller that relied on it must set this to true explicitly. Existing VMs are
    unaffected either way — a `remote-exec` provisioner only ever runs at
    create time, and the bootstrap now lives in its own `terraform_data`
    resource that is not created at all while this is false.

    Prefer leaving it off and using the cloud-init variables: the provisioner
    is a HARD dependency of `terraform apply`. No reachable SSH — wrong
    credentials, no DHCP lease yet, a firewall in the way, or a template with
    no matching user — fails the apply AFTER the VM already exists, leaving a
    tainted resource that the next apply destroys and recreates.

    Requires `vm_ssh_user` plus either `vm_ssh_password` or
    `vm_ssh_private_key`, and `vm_guest_agent = 1` so an IP is reported back.
  EOT
}

variable "vm_ssh_private_key" {
  default     = null
  type        = string
  sensitive   = true
  description = <<-EOT
    PEM-encoded private key for the SSH provisioner, as an alternative to
    `vm_ssh_password`. Only used when `vm_enable_ssh_provisioner` is true.
    Pair it with `vm_ci_ssh_keys` so the matching public key is actually
    authorized in the guest.
  EOT
}

variable "vm_bootstrap_reset_machine_id" {
  default     = false
  type        = bool
  description = <<-EOT
    Regenerate `/etc/machine-id` during the SSH bootstrap. Only used when
    `vm_enable_ssh_provisioner` is true.

    Clones inherit the template's machine-id, and systemd-networkd derives its
    default DHCPv4 client identifier from it — so several clones of one
    template can present the SAME identity to the DHCP server and be handed the
    same lease. Resetting fixes that.

    **It also changes the VM's IP address**, at the next renewal or reboot,
    because the DHCP identity is exactly what changed. The `ip` output was
    captured before that and becomes stale. That is why this defaults to false
    and why the provisioner no longer reboots: the module cannot both reset the
    identity and promise you a correct address.

    Prefer resetting the machine-id where nothing is holding the address yet —
    in the template build, or in a configuration-management step that reads the
    IP after the fact rather than before. Enable this only when you are not
    consuming the `ip` output.
  EOT
}

# =============================================================================
# STORAGE — cloud-init drive and root-disk tuning
#
# These exist because the module moved from Telmate's legacy `disk` block to
# its `disks` block. See docs/migration-disks.md.
# =============================================================================

variable "vm_cloudinit_datastore" {
  default     = null
  type        = string
  description = <<-EOT
    Datastore for the cloud-init (cidata) drive. Setting it emits a
    `cloudinit` block on `vm_cloudinit_slot`; leaving it null emits none, which
    renders exactly as the pre-migration module did.

    *** THIS IS WHAT MAKES EVERY vm_ci_* VARIABLE WORK. ***
    Without a cidata drive Proxmox has nowhere to put the generated user-data,
    so `vm_ci_user`, `vm_ci_password`, `vm_ci_ssh_keys`, `vm_ci_nameserver`
    and `vm_network_address0` are accepted and silently ignored. The old module
    could not create one at all: Telmate only configures it through the `disks`
    block, which conflicted with the legacy `disk` block.

    PICK A DATASTORE THAT SURVIVES A STOP/START. The cidata image is the one
    disk Proxmox frees and re-allocates on every power cycle. On LabUL's
    `V5010-01-1` that round trip is broken — the stop leaves an LV behind that
    no device node backs, and the next start dies on `lvcreate ... already
    exists` with the VM unbootable until the volume is deleted through the API.
    Point it at a filesystem-backed store (LabUL uses the NFS store
    `DD-sthings`) rather than at `pve_datastore`.
  EOT
}

variable "vm_cloudinit_slot" {
  default     = "ide2"
  type        = string
  description = <<-EOT
    Slot for the cloud-init drive. Only used when `vm_cloudinit_datastore` is
    set. `ide2` is the Proxmox convention and what the UI expects; change it
    only if the template already occupies that slot.

    Must not collide with `vm_bootdisk` — a precondition rejects that.
  EOT

  validation {
    condition     = contains(["ide0", "ide1", "ide2", "ide3"], var.vm_cloudinit_slot)
    error_message = "Valid values for vm_cloudinit_slot are ide0, ide1, ide2, ide3."
  }
}

variable "vm_disk_format" {
  default     = null
  type        = string
  description = <<-EOT
    Root disk format — `raw`, `qcow2` or `vmdk`. Unset leaves the provider
    default. Block-backed datastores (LVM, ZFS, Ceph) only accept `raw`;
    asking for `qcow2` there fails at apply time, not at plan time.
  EOT
}

variable "vm_disk_cache" {
  default     = null
  type        = string
  description = <<-EOT
    Root disk cache mode — `none`, `writethrough`, `writeback`, `unsafe`,
    `directsync`. Unset leaves the provider default. `unsafe` discards flushes
    and will corrupt the guest filesystem on host power loss; it is only
    reasonable for throwaway build VMs.
  EOT
}

variable "vm_disk_iothread" {
  default     = null
  type        = bool
  description = <<-EOT
    Give the disk its own I/O thread. Proxmox only honours this on the
    `virtio-scsi-single` controller — with `virtio-scsi-pci` (this module's
    default) the setting is accepted and ignored. Set
    `vm_storage_controller = "virtio-scsi-single"` alongside it; the module
    emits a `check` warning if you do not.
  EOT
}

variable "vm_disk_discard" {
  default     = null
  type        = bool
  description = <<-EOT
    Pass guest TRIM/discard through to the datastore, so deleting files inside
    the VM actually frees space on thin-provisioned storage. Needs a guest that
    issues discards (`fstrim`, or `discard` in the mount options).
  EOT
}

variable "vm_disk_emulate_ssd" {
  default     = null
  type        = bool
  description = <<-EOT
    Advertise the disk to the guest as an SSD (rotational=0).

    NOT AVAILABLE ON THE VIRTIO BUS — Telmate has no `emulatessd` attribute
    under `disks.virtio.*`, so with a `virtio*` boot slot this must stay unset.
    A precondition enforces that rather than letting it fail obscurely.
  EOT
}

variable "vm_disk_backup" {
  default     = null
  type        = bool
  description = "Include the root disk in vzdump backups. Unset leaves the provider default (included)."
}

variable "vm_disk_replicate" {
  default     = null
  type        = bool
  description = "Include the root disk in storage replication jobs. Unset leaves the provider default."
}
