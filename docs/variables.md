# Variables Reference

## Proxmox API

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `pve_api_url` | string | - | URL of Proxmox API (e.g. `https://pve:8006/api2/json`) |
| `pve_api_user` | string | - | API username (e.g. `terraform@pam`) |
| `pve_api_password` | string | - | API password |
| `pve_api_tls_verify` | bool | `true` | **Inverted name.** Wired to `pm_tls_insecure`, so `true` *disables* certificate checking. Set `false` to actually verify. |

## Infrastructure

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `pve_cluster_node` | string | - | Target Proxmox node name |
| `pve_datastore` | string | - | Storage backend for VM disks |
| `pve_folder_path` | string | - | VM pool/folder in Proxmox |
| `pve_network` | string | - | Network bridge (e.g. `vmbr101`) |

## VM Configuration

| Name | Type | Default | Validation | Description |
|------|------|---------|------------|-------------|
| `vm_count` | number | `1` | 1-5 | Number of VMs to create |
| `vm_name` | string | - | - | Base name (multi-VM adds suffix: `name-2`, `name-3`) |
| `vm_notes` | string | - | - | VM description shown in Proxmox UI |
| `vm_template` | string | - | - | Template to clone from |

## Compute

| Name | Type | Default | Validation | Description |
|------|------|---------|------------|-------------|
| `vm_num_cpus` | number | `2` | 2,4,6,8,10,12,16 | CPU cores |
| `vm_num_sockets` | number | `1` | - | CPU sockets |
| `vm_memory` | number | `4096` | 1024,2048,4096,8192 | Memory in MB |
| `vm_numa` | bool | `true` | - | Enable NUMA |

## Storage

| Name | Type | Default | Validation | Description |
|------|------|---------|------------|-------------|
| `vm_disk_size` | string | `"32G"` | 20G,32G,48G,64G,80G,96G,100G,128G,160G,196G,200G,256G,320G,512G,1024G | Disk size |
| `vm_bootdisk` | string | `"virtio0"` | virtio0/1, scsi0/1, sata0/1, ide0/1 | Boot disk slot. Selects a nested block in `disks`, so it is validated. Must match the TEMPLATE's root disk slot — `sthings-u26` is `virtio0`, not `scsi0`. |
| `vm_storage_controller` | string | `"virtio-scsi-pci"` | - | SCSI controller type |

## Firmware and OS

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `vm_firmware` | string | `"seabios"` | BIOS firmware type |
| `vm_os_type` | string | `"l26"` | Guest OS type for Proxmox optimizations |
| `vm_guest_agent` | number | `1` | QEMU guest agent (0=disabled, 1=enabled) |
| `vm_onboot` | bool | `true` | Start VM when Proxmox node boots |

## Network

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `vm_network_type` | string | `"virtio"` | Network card model |
| `vm_network_address0` | string | `"ip=dhcp"` | Cloud-init IP configuration |
| `vm_macaddr` | string | `null` | MAC address (auto-generated if null) |
| `vm_vlan_tag` | number | `-1` | VLAN tag for the NIC (e.g. on `vmbrvlan`). `-1` = untagged; valid `2`-`4094`. The sentinel is translated to "attribute omitted" — Telmate v3 rejects a literal `-1`. |

## Clone Source (opt-in)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `vm_clone_id` | number | `null` | Clone by template **VMID** rather than by name. Mutually exclusive with `vm_template`. Forces replacement on change. |
| `vm_full_clone` | bool | `null` | Full clone (`true`) vs linked clone (`false`). Unset leaves the provider default. Forces replacement on change. |
| `vm_id` | number | `null` | Pin the new VM's VMID. Unset lets Proxmox assign one. Only set before first create. |

## Cloud-init (opt-in)

All of these require the template to actually run cloud-init **and** to already
carry a cloud-init drive. Templates built without one accept every field and
silently ignore all of them.

!!! warning "Set `vm_cloudinit_datastore` or none of this takes effect"
    The cidata drive is what Proxmox writes the generated user-data to. Without
    it every field below is accepted and silently ignored. See
    [Migration: disk to disks](migration-disks.md).

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `vm_ci_os_type` | string | `null` | Telmate `os_type` — `cloud-init`, `ubuntu`, `centos`. **Not** `vm_os_type`, which is `qemu_os`. |
| `vm_ci_user` | string | `null` | Default cloud-init user (`ciuser`). |
| `vm_ci_password` | string | `null` | Password for that user (`cipassword`). Proxmox returns it hashed, so changing it does not rotate it on a live VM. |
| `vm_ci_ssh_keys` | list(string) | `null` | Authorized public keys, one full key per element; joined with newlines. |
| `vm_ci_upgrade` | bool | `null` | Package upgrade on first boot (`ciupgrade`). |
| `vm_ci_nameserver` | string | `null` | DNS servers — **space**-separated in a single string, not comma. |
| `vm_ci_searchdomain` | string | `null` | DNS search domain. |

!!! warning "Set a password or a key alongside `vm_ci_user`"
    With `ciuser` set and neither, cloud-init applies its `lock_passwd` default
    and **locks the account**, wiping the password baked into the template at
    build time. The module emits a `check` warning for this.

## Hardware Extras (opt-in)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `vm_cpu_type` | string | `null` | CPU model, e.g. `host`, `x86-64-v2-AES`. `host` blocks live migration across differing CPUs. |
| `vm_balloon` | number | `null` | Balloon minimum in MiB; must be ≤ `vm_memory`. Unset pins memory. |
| `vm_tags` | list(string) | `null` | Proxmox tags, comma-joined. Pass lowercase and sorted — Proxmox normalises server-side. |
| `vm_network_firewall` | bool | `null` | Proxmox firewall on the NIC. |
| `vm_network_mtu` | number | `null` | NIC MTU; `1` inherits from the bridge. |
| `vm_smbios_manufacturer` | string | `null` | SMBIOS manufacturer. Setting either SMBIOS field emits the block. Forces replacement. |
| `vm_smbios_product` | string | `null` | SMBIOS product. |

## UEFI (opt-in)

| Name | Type | Default | Validation | Description |
|------|------|---------|------------|-------------|
| `vm_efi_disk_storage` | string | `null` | - | Datastore for the EFI vars disk. **Required with `vm_firmware = "ovmf"`** — without it OVMF cannot persist boot entries and drops to the EFI shell. |
| `vm_efi_disk_type` | string | `"4m"` | 2m,4m | EFI vars disk type. Only used when `vm_efi_disk_storage` is set. |
| `vm_efi_disk_pre_enrolled_keys` | bool | `false` | - | Pre-enroll Microsoft Secure Boot keys. Refuses unsigned kernels and out-of-tree modules. |

## Storage (opt-in)

| Name | Type | Default | Validation | Description |
|------|------|---------|------------|-------------|
| `vm_cloudinit_datastore` | string | `null` | - | Datastore for the cloud-init (cidata) drive. **Required for any `vm_ci_*` field to take effect.** |
| `vm_cloudinit_slot` | string | `"ide2"` | ide0-ide3 | Slot for that drive. Must not collide with `vm_bootdisk`. |
| `vm_disk_format` | string | `null` | - | `raw`, `qcow2`, `vmdk`. Block stores (LVM/ZFS/Ceph) only accept `raw`, and the failure comes at apply time. |
| `vm_disk_cache` | string | `null` | - | `none`, `writethrough`, `writeback`, `unsafe`, `directsync`. |
| `vm_disk_iothread` | bool | `null` | scsi/virtio only | Dedicated I/O thread. Proxmox only honours it on `virtio-scsi-single`. |
| `vm_disk_discard` | bool | `null` | - | Pass guest TRIM through to thin-provisioned storage. |
| `vm_disk_emulate_ssd` | bool | `null` | ide/sata/scsi only | Advertise the disk to the guest as an SSD. |
| `vm_disk_backup` | bool | `null` | - | Include in vzdump backups. |
| `vm_disk_replicate` | bool | `null` | - | Include in storage replication jobs. |

!!! danger "The `disks` block is authoritative"
    Any slot it does not declare is sent to Proxmox with `delete=1` — a no-op
    on an empty slot, a **removal** on an occupied one. The module declares one
    data disk plus an optional cidata drive, so a disk you added by hand in the
    Proxmox UI will be removed on the next apply.

    ```bash
    qm config <vmid> | grep -E '^(virtio|scsi|sata|ide)[0-9]+:'
    ```

!!! warning "Per-bus attribute limits"
    Telmate exposes different attributes per bus, and preconditions enforce it:
    `iothread` is scsi/virtio only, `emulatessd` is ide/sata/scsi only.

## SSH Provisioner (opt-in)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `vm_enable_ssh_provisioner` | bool | `false` | Run the post-clone bootstrap: set the hostname over SSH. No reboot. |
| `vm_ssh_user` | string | `""` | SSH username for that bootstrap. |
| `vm_ssh_password` | string | `""` | SSH password for that bootstrap. |
| `vm_ssh_private_key` | string | `null` | PEM private key, as an alternative to the password. |
| `vm_bootstrap_reset_machine_id` | bool | `false` | Regenerate `/etc/machine-id`. **Changes the VM's IP.** See below. |

!!! danger "This used to run unconditionally"
    It now defaults to **off**. Existing VMs are unaffected — a `remote-exec`
    provisioner only runs at create time — but a caller that relied on it must
    now set `vm_enable_ssh_provisioner = true`.

    Prefer cloud-init instead. The provisioner is a hard dependency of
    `terraform apply`: unreachable SSH fails the apply *after* the VM already
    exists, leaving a tainted resource that the next apply destroys and
    recreates.

!!! warning "`vm_bootstrap_reset_machine_id` moves the VM's IP address"
    systemd-networkd derives its default DHCPv4 client identifier from
    `/etc/machine-id`. Regenerating it changes the DHCP identity, so the VM
    takes a **different lease** at the next renewal or reboot — and the `ip`
    output, captured before that, goes stale. A DNS record or IP reservation
    made from it would point at an address nobody answers on.

    It exists because clones inherit the template's machine-id, so several
    clones can present the same identity to the DHCP server and be handed the
    same lease. That is a real problem — but the module cannot both reset the
    identity and promise a correct address.

    Reset it where nothing holds the address yet: in the template build, or in
    a configuration-management step that reads the IP afterwards rather than
    before. Enable this only when you are not consuming the `ip` output.

    This is also why the bootstrap no longer reboots. The old version rebooted
    after resetting the machine-id and then reconnected to the create-time
    address — which failed **every** apply, after a 5 minute timeout. Verified
    on a live cluster on 2026-08-25.
