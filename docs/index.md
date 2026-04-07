# Proxmox VM

Terraform module for creating Proxmox virtual machines based on the [Telmate/proxmox](https://registry.terraform.io/providers/Telmate/proxmox/latest) provider (v3.x).

## Overview

This module provisions VMs on Proxmox VE by cloning templates. It supports:

- Multi-VM creation (1-5 VMs per invocation)
- Cloud-init configuration with DHCP or static IPs
- CPU, memory, disk, and network customization
- QEMU guest agent integration
- Automatic hostname provisioning via SSH

## Quick Start

```hcl
module "proxmox-vm" {
  source           = "git::https://github.com/stuttgart-things/proxmox-vm.git"
  pve_api_url      = "https://pve.example.com:8006/api2/json"
  pve_api_user     = "terraform@pam"
  pve_api_password = "secret"
  pve_cluster_node = "pve1"
  pve_datastore    = "local-lvm"
  pve_folder_path  = "terraform"
  pve_network      = "vmbr0"
  vm_name          = "my-vm"
  vm_template      = "ubuntu22"
  vm_num_cpus      = 4
  vm_memory        = 4096
  vm_disk_size     = "32G"
  vm_ssh_user      = "ubuntu"
  vm_ssh_password  = "password"
}
```

## Outputs

| Name | Description |
|------|-------------|
| `ip` | IPv4 addresses of created VMs |
| `mac` | MAC addresses of created VMs |
| `id` | Proxmox VM IDs |

## Crossplane Integration

This module can also be used with [Crossplane](https://crossplane.io/) via the Upbound Terraform Provider as a `Workspace` resource. See the [README](https://github.com/stuttgart-things/proxmox-vm#crossplane-usage) for a full example.

## Related Documentation

- [Variables Reference](variables.md)
- [Proxmox API Discovery](proxmox-api-discovery.md)
- [CI/CD](CICD.md)
