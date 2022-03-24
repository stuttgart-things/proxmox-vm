stuttgart-things/proxmox-vm
=========================================

terraform module to build a proxmox vm /w config from a generic vm-template

### Example to use this terraform module

Get the exmaple main.tf and set your variables

```
cat <<EOF > main.tf
terraform {


  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = ">= 2.9.6"
    }
  }
}

provider "proxmox" {
    pm_api_url      = var.pve_api_url
    pm_user         = var.pve_api_user
    pm_password     = var.pve_api_password
    pm_tls_insecure = var.pve_api_tls_verify
}

module "proxmox-vm" {
  source                  = "https://artifacts.labul.sva.de/modules/proxmox-vm.zip"
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
  default     = "https://sthings-pve1.labul.sva.de:8006/api2/json"
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
EOF
```
Run terraform init to download the module and provider

```
terraform init
```

Apply to create the tf ressources in proxmox

```
terraform apply
```

To delete the tf managed ressources run destroy

```
terraform destroy
```

## Available terraform variables:
The variables are documented in the file: [variables.tf](https://codehub.sva.de/Lab/stuttgart-things/virtual-machines/proxmox-vm-cloudinit/-/blob/master/variables.tf) 

## Terraform provider
For more information about the tf provider see:

- [Github](https://github.com/Telmate/terraform-provider-proxmox)
- [Terraform registry](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs) 

## Requirements and Dependencies:
- [Terraform](https://www.terraform.io/downloads.html) 1.0.11 or greater

## Outputs

 - `ip` - ip address of created vm
 - `mac` - mac address of created vm
 - `id` - proxmox id of created vm

## Version:
```
DATE           WHO            WHAT
2021-09-13     Marcel Zapf    Create tf module
```

License
-------

BSD

Author Information
------------------

Marcel Zapf; 09/2021; SVA GmbH
