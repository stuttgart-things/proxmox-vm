# stuttgart-things/proxmox-vm

Terraform module for creating Proxmox virtual machines based on the [Telmate/proxmox](https://registry.terraform.io/providers/Telmate/proxmox/latest) provider (v3.x).

## Usage

```hcl
module "proxmox-vm" {
  source             = "git::https://github.com/stuttgart-things/proxmox-vm.git"
  pve_api_url        = var.pve_api_url
  pve_api_user       = var.pve_api_user
  pve_api_password   = var.pve_api_password
  pve_api_tls_verify = var.pve_api_tls_verify
  pve_cluster_node   = "sthings-pve1"
  pve_datastore      = "datastore"
  pve_folder_path    = "stuttgart-things"
  pve_network        = "vmbr101"
  vm_count           = 1
  vm_name            = "my-vm"
  vm_notes           = "created by terraform"
  vm_template        = "ubuntu22"
  vm_num_cpus        = 4
  vm_memory          = 4096
  vm_disk_size       = "32G"
  vm_ssh_user        = var.vm_ssh_user
  vm_ssh_password    = var.vm_ssh_password
}

output "ip" {
  value = module.proxmox-vm.ip
}
```

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `pve_api_url` | string | - | URL of Proxmox API |
| `pve_api_user` | string | - | Proxmox API username |
| `pve_api_password` | string | - | Proxmox API password |
| `pve_api_tls_verify` | bool | `true` | Verify TLS certificate |
| `pve_cluster_node` | string | - | Proxmox cluster node name |
| `pve_datastore` | string | - | Proxmox datastore name |
| `pve_folder_path` | string | - | VM folder/pool path |
| `pve_network` | string | - | Proxmox network bridge |
| `vm_count` | number | `1` | Number of VMs (1-5) |
| `vm_name` | string | - | VM name |
| `vm_notes` | string | - | VM description |
| `vm_template` | string | - | Template to clone from |
| `vm_num_cpus` | number | `2` | CPU cores (2,4,6,8,10,12,16) |
| `vm_num_sockets` | number | `1` | CPU sockets |
| `vm_memory` | number | `4096` | Memory in MB (1024,2048,4096,8192) |
| `vm_disk_size` | string | `"32G"` | Disk size (20G-256G) |
| `vm_bootdisk` | string | `"virtio0"` | Boot disk slot |
| `vm_storage_controller` | string | `"virtio-scsi-pci"` | SCSI controller type |
| `vm_firmware` | string | `"seabios"` | BIOS firmware |
| `vm_os_type` | string | `"l26"` | Guest OS type |
| `vm_guest_agent` | number | `1` | QEMU guest agent (0/1) |
| `vm_numa` | bool | `true` | Enable NUMA |
| `vm_onboot` | bool | `true` | Start VM on node boot |
| `vm_network_type` | string | `"virtio"` | Network card model |
| `vm_network_address0` | string | `"ip=dhcp"` | IP config for cloud-init |
| `vm_macaddr` | string | `null` | MAC address (optional) |
| `vm_ssh_user` | string | `""` | SSH username for provisioner |
| `vm_ssh_password` | string | `""` | SSH password for provisioner |

## Outputs

| Name | Description |
|------|-------------|
| `ip` | IPv4 addresses of created VMs |
| `mac` | MAC addresses of created VMs |
| `id` | Proxmox VM IDs |

## Crossplane Usage

This module can be used with the [Upbound Terraform Provider](https://marketplace.upbound.io/providers/upbound/provider-terraform/) for Crossplane:

```yaml
apiVersion: tf.upbound.io/v1beta1
kind: Workspace
metadata:
  name: appserver
spec:
  providerConfigRef:
    name: terraform-default
  forProvider:
    source: Remote
    module: git::https://github.com/stuttgart-things/proxmox-vm.git
    vars:
      - key: vm_count
        value: "1"
      - key: vm_name
        value: appserver
      - key: vm_template
        value: ubuntu22
      - key: vm_num_cpus
        value: "4"
      - key: vm_memory
        value: "4096"
      - key: vm_disk_size
        value: 128G
      - key: pve_network
        value: vmbr103
      - key: pve_datastore
        value: v3700
      - key: pve_folder_path
        value: stuttgart-things
      - key: pve_cluster_node
        value: sthings-pve1
    varFiles:
      - source: SecretKey
        secretKeyRef:
          namespace: default
          name: pve-tfvars
          key: terraform.tfvars
```

## License

BSD

## Author Information

stuttgart-things
