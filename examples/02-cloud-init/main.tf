# ============================================================================
# 02 — CLOUD-INIT (the recommended path)
#
# Provision the guest through Proxmox cloud-init instead of the SSH bootstrap:
# no post-create SSH dependency, so `terraform apply` cannot fail after the VM
# already exists. The hostname comes from the VM name, which Proxmox writes
# into the generated user-data.
#
# *** vm_cloudinit_datastore IS WHAT MAKES THIS WORK. ***
# Without it Proxmox has no cidata drive to write the generated user-data to,
# and every vm_ci_* field below is accepted and silently ignored — a static IP
# that never materialises is the usual symptom, with nothing in the plan or the
# apply output pointing at the cause. The module emits a `check` warning.
#
# Before the disk -> disks migration this module could not create the drive at
# all, and worse: the legacy `disk` block sent every undeclared slot to Proxmox
# with delete=1, so a cidata drive the TEMPLATE shipped was removed on the
# first apply. See docs/migration-disks.md.
#
# The template must still not ship /etc/cloud/cloud-init.disabled — with that
# file present cloud-init never runs, every clone keeps the template's
# hostname, and again nothing points at the template.
#
# WHY BOTH A PASSWORD AND KEYS: with `ciuser` set and no password, cloud-init
# applies its `lock_passwd` default and LOCKS the account, wiping the password
# baked in at build time. That breaks any later password-based Ansible run even
# though key-based SSH still works.
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

  vm_name     = "cloudinit-demo"
  vm_template = "ubuntu24-cloudinit"
  vm_num_cpus = 4
  vm_memory   = 8192

  # Static IPv4. The gateway rides along in the same string; use "ip=dhcp" for
  # a lease instead.
  vm_network_address0 = "ip=10.31.101.50/24,gw=10.31.101.1"

  # --- opt-in: cloud-init ---
  # A datastore that survives a stop/start. The cidata image is freed and
  # re-allocated on every power cycle, which some block stores handle badly.
  vm_cloudinit_datastore = "local-lvm"

  vm_ci_os_type      = "cloud-init"
  vm_ci_user         = "sthings"
  vm_ci_password     = var.ci_password
  vm_ci_ssh_keys     = var.ci_ssh_keys
  vm_ci_nameserver   = "10.31.101.20 10.31.101.21" # SPACE-separated, not comma
  vm_ci_searchdomain = "labul.sva.de"
  vm_ci_upgrade      = false # leave patching to Ansible; saves minutes of boot

  vm_tags = ["terraform", "cloudinit"]
}

variable "ci_password" {
  type      = string
  sensitive = true
}

variable "ci_ssh_keys" {
  type        = list(string)
  description = "One full public key per element; the module joins them for Proxmox."
}

output "ip" {
  value = module.vm.ip
}
