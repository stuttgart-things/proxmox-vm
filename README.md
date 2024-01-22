# stuttgart-things/proxmox-vm

terraform for creating proxmox vms

## EXAMPLE USAGE TERRAFORM

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
terraform init
terraform apply
terraform destroy
```

</details>

## EXAMPLE USAGE CROSSPLANE

<details><summary><b>TFVARS (SECRETS)</b></summary>

```hcl
pve_api_url="<API-URL>"
pve_api_user="<API-USER>"
pve_api_password="<API-PASSWORD>"
vm_ssh_user="<SSH-USER>"
vm_ssh_password="<SSH-PASSWORD>"
```

```bash
kubectl create secret generic pve-tfvars --from-file=terraform.tfvars
```

</details>


<details><summary><b>WORKSPACE</b></summary>

```yaml
---
apiVersion: tf.upbound.io/v1beta1
kind: Workspace
metadata:
  name: appserver
  annotations:
    crossplane.io/external-name: pve-vm
spec:
  providerConfigRef:
    name: terraform-default
  forProvider:
    source: Remote
    module: git::https://github.com/stuttgart-things/proxmox-vm.git?ref=v2.9.14-1.5.5
    vars:
      - key: vm_count
        value: "1"
      - key: vm_num_cpus
        value: "4"
      - key: vm_memory
        value: "4096"
      - key: vm_name
        value: appserver
      - key: vm_template
        value: ubuntu22
      - key: pve_network
        value: vmbr103
      - key: pve_datastore
        value: v3700
      - key: vm_disk_size
        value: 128G
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
  writeConnectionSecretToRef:
    namespace: default
    name: terraform-workspace-appserver
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
