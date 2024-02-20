# stuttgart-things/proxmox-vm

terraform module for creating proxmox vms

## EXAMPLE USAGE TERRAFORM

<details><summary><b>CREATE PVE VM</b></summary>

```hcl
# CALL MODULE - main.tf
# main.tf
module "proxmox-vm" {
  source                  = "git::https://github.com/stuttgart-things/proxmox-vm.git"
  pve_api_url             = var.pve_api_url
  pve_api_user            = var.pve_api_user
  pve_api_password        = var.pve_api_password
  pve_api_tls_verify      = var.pve_api_tls_verify

  pve_cluster_node        = "sthings-pve1"
  pve_datastore           = "datastore"
  pve_folder_path         = "stuttgart-things"
  pve_network             = "vmbr101"
  vm_count                = 1
  vm_name                 = "vm-test-name"
  vm_notes                = "vm-info"
  vm_template             = "ubuntu22"
  vm_num_cpus             = "4"
  vm_memory               = "4096"
  vm_disk_size            = "32G"
  vm_ssh_user             = var.vm_ssh_user
  vm_ssh_password         = var.vm_ssh_password
}

output "ip" {
  value     = module.proxmox-vm.ip
}

output "mac" {
  value     = module.proxmox-vm.mac
}

output "id" {
  value     = module.proxmox-vm.id
}


variable "pve_api_url" {
  description = "url of proxmox api. Example: https://server-example.sva.de:8006/api2/json"
}
 
variable "pve_api_user" {
  description = "username of proxmox api user"
}
 
variable "pve_api_password" {
  description = "password of proxmox api user"
}
 
variable "vm_ssh_user" {
  description = "desired username for ssh connection"
}
 
variable "vm_ssh_password" {
  description = "desired password for ssh connection"
}
 
variable "pve_api_tls_verify" {
  description = "proxmox API disable check if cert is valid"
}
 ```

```
# VARIABLES -tfvars
pve_api_url="<API-URL>"  
pve_api_user="<API-USER>"
pve_api_password="<API-PASSWORD>"
pve_api_tls_verify = true
vm_ssh_user="<SSH-USER>"
vm_ssh_password="<SSH-PASSWORD>"
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
