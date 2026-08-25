# Proxmox VM

Terraform module for creating Proxmox virtual machines based on the [Telmate/proxmox](https://registry.terraform.io/providers/Telmate/proxmox/latest) provider (v3.x).

## Overview

This module provisions VMs on Proxmox VE by cloning templates. It supports:

- Multi-VM creation (1-5 VMs per invocation)
- Cloud-init: cidata drive, user, password, SSH keys, DNS, DHCP or static IPs
- Clone by template name **or** by template VMID
- CPU, memory, disk, VLAN and network customization
- UEFI/OVMF with an EFI vars disk
- SMBIOS overrides
- QEMU guest agent integration
- Optional legacy hostname provisioning over SSH

## Quick Start

```hcl
module "proxmox-vm" {
  source           = "git::https://github.com/stuttgart-things/proxmox-vm.git"
  pve_api_url      = "https://pve.example.com:8006/api2/json"
  pve_api_user     = "terraform@pam"
  pve_api_password = var.pve_api_password
  pve_cluster_node = "pve1"
  pve_datastore    = "local-lvm"
  pve_folder_path  = "terraform"
  pve_network      = "vmbr0"
  vm_name          = "my-vm"
  vm_template      = "ubuntu22"
  vm_num_cpus      = 4
  vm_memory        = 4096
  vm_disk_size     = "32G"
}
```

See [Examples](examples.md) for annotated, runnable configurations — including
cloud-init, UEFI, cloning by VMID, and a field-by-field port of the Crossplane
`NativeProxmoxVM` XR.

## Outputs

| Name | Description |
|------|-------------|
| `ip` | IPv4 addresses of created VMs (requires `vm_guest_agent = 1`) |
| `ipv6` | IPv6 addresses, when the guest agent reports one |
| `mac` | MAC addresses of created VMs |
| `id` | Provider resource IDs, `<node>/qemu/<vmid>` |
| `vmid` | Proxmox VMIDs, as numbers |
| `name` | VM names, in count order |

## Crossplane Integration

This module can also be used with [Crossplane](https://crossplane.io/) via the Upbound Terraform Provider as a `Workspace` resource. See the [README](https://github.com/stuttgart-things/proxmox-vm#crossplane-usage) for a full example.

## Related Documentation

- [Examples](examples.md)
- [Migration: disk to disks](migration-disks.md)
- [Provider Versions](provider-versions.md)
- [Variables Reference](variables.md)
- [Proxmox API Discovery](proxmox-api-discovery.md)
- [CI/CD](CICD.md)
