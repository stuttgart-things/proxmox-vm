# ============================================================================
# 07 — THE LEGACY SSH BOOTSTRAP
#
# This is what the module used to do unconditionally on every create: SSH in,
# write /etc/hostname, regenerate the machine-id, reboot, wait. It is now
# opt-in behind vm_enable_ssh_provisioner.
#
# USE IT ONLY when the template does not run cloud-init. If it does, example 02
# gets you the same hostname with none of the failure modes below.
#
# THE FAILURE MODE: the provisioner is a hard dependency of `terraform apply`.
# No reachable SSH — wrong credentials, no DHCP lease yet, a firewall in the
# way, sshd not up — fails the apply AFTER the VM already exists. The VM is
# left running and the resource tainted, so the next apply destroys and
# recreates it. That is why it moved out of the VM resource and into its own
# terraform_data: a tainted bootstrap no longer drags the VM down with it.
#
# vm_guest_agent = 1 is enforced by a precondition: without the agent Proxmox
# never reports an IP, so there is nothing to connect to.
# ============================================================================

module "vm" {
  source = "../../"

  pve_api_url        = var.pve_api_url
  pve_api_user       = var.pve_api_user
  pve_api_password   = var.pve_api_password
  pve_api_tls_verify = var.pve_api_tls_verify

  pve_cluster_node = "sthings-pve1"
  pve_datastore    = "datastore"
  pve_folder_path  = "stuttgart-things"
  pve_network      = "vmbr101"

  vm_name     = "legacy-bootstrap"
  vm_template = "ubuntu22"

  vm_guest_agent = 1

  # --- opt-in: restore the pre-existing behaviour ---
  vm_enable_ssh_provisioner = true
  vm_ssh_user               = var.vm_ssh_user
  vm_ssh_password           = var.vm_ssh_password

  # Key-based alternative — pair it with vm_ci_ssh_keys so the matching public
  # key is actually authorized in the guest:
  # vm_ssh_private_key = file("~/.ssh/id_ed25519")
}

variable "vm_ssh_user" {
  type = string
}

variable "vm_ssh_password" {
  type      = string
  sensitive = true
}

output "ip" {
  value = module.vm.ip
}
