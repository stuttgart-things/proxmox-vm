# ============================================================================
# 06 — THE NativeProxmoxVM XR, EXPRESSED AS TERRAFORM
#
# A field-by-field port of the reference Crossplane XR
#   crossplane/xrs/examples/nativeproxmoxvm.yaml  (u26-kind2, LabUL / ul-pve02)
# so the two paths can be compared directly. That XR runs through the *bpg*
# provider; this module runs through *Telmate*, so a few things map differently
# and two do not map at all. Both are called out below.
#
# ---------------------------------------------------------------------------
# MAPS CLEANLY
#   spec.vm.name / cpu / memory          -> vm_name / vm_num_cpus / vm_memory
#   spec.vm.node                         -> pve_cluster_node
#   spec.vm.datastore                    -> pve_datastore
#   spec.vm.bridge + vlanTag             -> pve_network + vm_vlan_tag
#   spec.vm.pool                         -> pve_folder_path
#   spec.vm.templateVmId                 -> vm_clone_id
#   spec.vm.agentEnabled                 -> vm_guest_agent
#   spec.cloudInit.ipv4Address: dhcp     -> vm_network_address0
#   status.share.ip                      -> output.ip
#
# DIFFERENT MECHANISM, SAME EFFECT
#   spec.vm.cloneDatastore
#     The XR needs it because bpg otherwise allocates the clone on the
#     TEMPLATE's datastore and moves the disk afterwards — which on LabUL 403s,
#     since the SVATemplates ACL lost Datastore.AllocateSpace. Telmate passes
#     the target storage straight into the clone call, so `pve_datastore` alone
#     already gives you the "clone directly onto the target" behaviour. There
#     is no separate knob, and none is needed.
#
#   SMBIOS
#     The XR's Composition always emits an smbios block to dodge bpg's
#     base64-decode-on-read bug against PegaProx's plain-text stamp. Telmate
#     does not have that bug, so this is opt-in here. It is still worth setting
#     on LabUL: a VM that already carries SMBIOS keys is skipped by PegaProx's
#     needs_smbios_update(), which keeps the node's systemd service out of your
#     VM entirely.
#
# DOES NOT MAP — you need something else for these
#   spec.ansible.*
#     The XR emits an AnsibleRun (-> Tekton PipelineRun) once the VM is Ready
#     with an IP, which is what actually installs base-OS and kind. This module
#     has no equivalent. Drive it from the `ip` output: a null_resource with a
#     local-exec ansible-playbook, an ansible_playbook resource, or a standalone
#     AnsibleRun CR now that the address is known. Sketch at the bottom.
#
#   spec.vm.templateNode
#     Telmate locates the template by ID across the cluster, so there is no
#     separate "node the template lives on" field to get wrong.
#
#   spec.cloudInit.snippetsDatastore
#     bpg-only (it uploads a meta-data snippet over SSH to the node).
#
# NOW MAPS, AS OF THE disk -> disks MIGRATION
#   spec.cloudInit.datastoreId / EnvironmentConfig cloudInitDatastore
#     -> vm_cloudinit_datastore. Same reasoning as the XR: point it at the NFS
#     store DD-sthings, NOT at V5010-01-1. The cidata image is the one disk PVE
#     frees and re-allocates on every stop/start, and on V5010-01-1 that round
#     trip leaves an LV behind that no device node backs — the next start dies
#     on `lvcreate ... already exists` and the VM stays unbootable until the
#     volume is deleted through the API.
# ============================================================================

module "kind_vm" {
  source = "../../"

  pve_api_url        = var.pve_api_url
  pve_api_user       = var.pve_api_user
  pve_api_password   = var.pve_api_password
  pve_api_tls_verify = var.pve_api_tls_verify

  # Placement — the XR gets these from the `labul` EnvironmentConfig; here they
  # are explicit. A tfvars file or a thin wrapper module is the equivalent of
  # that EnvironmentConfig.
  pve_cluster_node = "ul-pve02"
  pve_datastore    = "V5010-01-1"
  pve_folder_path  = "stuttgart-things"
  pve_network      = "vmbrvlan"
  vm_vlan_tag      = 102

  vm_name  = "u26-kind2"
  vm_notes = "kind box; managed by terraform"

  # spec.vm.templateVmId: "144" — ubuntu26-base-os
  vm_clone_id   = 144
  vm_full_clone = true

  # spec.vm: cpu 8 / memory 16384 / disk 100
  vm_num_cpus  = 8
  vm_memory    = 16384
  vm_disk_size = "100G"

  # spec.vm.agentEnabled: true — REQUIRED for the ip output to ever populate.
  vm_guest_agent = 1

  # spec.cloudInit.ipv4Address: dhcp
  vm_network_address0 = "ip=dhcp"

  # NFS, deliberately not V5010-01-1 — see the header note.
  vm_cloudinit_datastore = "DD-sthings"

  vm_ci_os_type  = "cloud-init"
  vm_ci_user     = "sthings"
  vm_ci_password = var.ci_password
  vm_ci_ssh_keys = var.ci_ssh_keys

  # PegaProx opt-out, matching the Composition's defaults.
  vm_smbios_manufacturer = "stuttgart-things"
  vm_smbios_product      = "terraform-proxmox-vm"

  vm_tags = ["kind", "labul", "terraform"]
}

variable "ci_password" {
  type      = string
  sensitive = true
}

variable "ci_ssh_keys" {
  type = list(string)
}

output "ip" {
  value = module.kind_vm.ip
}

# ---------------------------------------------------------------------------
# The spec.ansible half, if you want it. Uncomment and adapt — deliberately
# left inert, since it shells out on the machine running Terraform.
#
# The XR's varsFile entries become -e flags; `vm_hostname` is redundant here
# because Proxmox cloud-init already sets the hostname from the VM name.
# ---------------------------------------------------------------------------
#
# resource "terraform_data" "kind" {
#   triggers_replace = [module.kind_vm.vmid]
#
#   provisioner "local-exec" {
#     command = <<-CMD
#       ansible-playbook sthings.container.kind \
#         -i '${module.kind_vm.ip[0]},' \
#         -u sthings \
#         -e ansible_user=sthings \
#         -e kind_cluster_name=kind2 \
#         -e install_kind=true \
#         -e create_kind_cluster=true \
#         -e count_controlplane_nodes=1 \
#         -e count_worker_nodes=2 \
#         -e rebuild_kind_cluster=false \
#         -e enable_ingress_ports=true \
#         -e update_kubeconfig_ip=true \
#         -e fetch_kubeconfig=false
#     CMD
#   }
# }
