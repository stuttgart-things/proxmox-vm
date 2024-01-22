# stuttgart-things/proxmox-vm

terraform for creating proxmox vms

## EXAMPLE USAGE

<details><summary><b>CREATE PVE VM</b></summary>

```hcl
provider "proxmox" {
    pm_api_url      = var.pve_api_url
    pm_user         = var.pve_api_user
    pm_password     = var.pve_api_password
    pm_tls_insecure = var.pve_api_tls_verify
}

module "proxmox-vm" {
  source                  = "git::https://github.com/stuttgart-things/proxmox-vm.git"
  pve_cluster_node        = "sthings-pve1"
  pve_datastore           = "datastore"
  pve_folder_path         = "stuttgart-things"
  pve_network             = "vmbr0"
  vm_count                = 1
  vm_name                 = "cstream8-test"
  vm_notes                = "cstream8-blal"
  vm_template             = "cstream8"
  vm_num_cpus             = "4"
  vm_memory               = "4096"
  vm_disk_size            = "35G"
}

output "ip" {
  value     = module.proxmox.ip
}

output "mac" {
  value     = module.proxmox.mac
}

output "id" {
  value     = module.proxmox.id
}

variable "pve_api_url" {
  default     = "https://sthings-pve1.example.com:8006/api2/json"
  description = "url of proxmox api"
}

variable "pve_api_user" {
  default     = "terraform@pve"
  description = "username of proxmox api user"
}

variable "pve_api_password" {
  default     = "{{ your_password}}"
  description = "password of proxmox api user"
}

variable "pve_api_tls_verify" {
  default     = true
  description = "proxmox API disable check if cert is valid"
}
```

</details>

<details><summary><b>EXECUTION</b></summary>

```bash
# Run terraform init to download the module and provider
terraform init
```

```bash
# Apply to create the tf ressources in proxmox
terraform apply
```

```bash
# To delete the tf managed ressources run destroy
terraform destroy
```

</details>

## OUTPUTS

 - `ip` - ip address of created vm
 - `mac` - mac address of created vm
 - `id` - proxmox id of created vm

License
-------

BSD

Author Information
------------------

Marcel Zapf; 09/2021; Stuttgart-Things
