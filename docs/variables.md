# Variables Reference

## Proxmox API

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `pve_api_url` | string | - | URL of Proxmox API (e.g. `https://pve:8006/api2/json`) |
| `pve_api_user` | string | - | API username (e.g. `terraform@pam`) |
| `pve_api_password` | string | - | API password |
| `pve_api_tls_verify` | bool | `true` | Verify TLS certificate |

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
| `vm_disk_size` | string | `"32G"` | 20G,32G,64G,96G,128G,196G,256G | Disk size |
| `vm_bootdisk` | string | `"virtio0"` | - | Boot disk slot |
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

## SSH Provisioner

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `vm_ssh_user` | string | `""` | SSH username for post-clone provisioning |
| `vm_ssh_password` | string | `""` | SSH password for post-clone provisioning |

The SSH provisioner sets the hostname and regenerates the machine-id after cloning.
