# ============================================================================
# 09 — THE CONFIGURATION THAT ACTUALLY BUILT A VM
#
# Not a sketch. This exact configuration was applied against LabUL on
# 2026-08-24, produced VM 9101 on ul-pve10, was verified against the live
# Proxmox config, planned clean a second time, and was then destroyed.
#
# It is kept as the starting point for the Dagger/Terraform build of the next
# set of VMs. Everything below is a value that was checked against the API on
# that date rather than copied out of a document — because every document
# describing this cluster had already drifted.
#
# ---------------------------------------------------------------------------
# WHAT THE LIVE VM LOOKED LIKE
#
#   ide2      DD-sthings:9101/vm-9101-cloudinit.raw,media=cdrom
#   virtio0   V5010-01-1:vm-9101-disk-1,replicate=0,size=32G
#   ciuser    sthings
#   smbios1   uuid=…,manufacturer=c3R1dHRnYXJ0LXRoaW5ncw==,product=…
#   tags      smoketest;terraform
#   net0      virtio=BC:24:11:51:C7:9F,bridge=vmbrvlan,tag=101
#   boot      order=virtio0;net0
#
# The `ide2` line is the point: the TEMPLATE HAS NO CLOUD-INIT DRIVE. None of
# them do. The module created it. That was impossible before the disk -> disks
# migration.
#
# ---------------------------------------------------------------------------
# TWO CONSTRAINTS YOU CANNOT DESIGN AROUND RIGHT NOW
#
# 1. Templates 144, 192 and 211 cannot be cloned. The reason CHANGED on
#    2026-08-25: ul-pve11's storage API used to time out (596 after 30 s) and
#    now answers in 0.3 s again -- but those templates live on DD-sthings,
#    where a more specific ACL grants only SVATemplates (AllocateTemplate +
#    Audit, no AllocateSpace) and REPLACES the broader /storage grant. The
#    provider clones to the SOURCE storage before moving, so the clone itself
#    is denied with 403 no matter what pve_datastore says.
#    => Never put a root disk on DD-sthings. The cidata drive there is fine.
#    See docs/labul-ul-pve11-incident.md.
#
# 2. That leaves template 110 (sthings-u26, ul-pve10) as the only usable Linux
#    template — and 110 ships /etc/cloud/cloud-init.disabled, so the GUEST
#    ignores the cidata drive. The drive is created and correct; nothing reads
#    it. So on 110 the cloud-init user, password, keys and static IP below do
#    not reach the guest.
#
#    => For a guest that really consumes cloud-init, template 211 has to
#       become clonable -- which now needs an ACL or a storage move, not a
#       node repair. Until then, either accept the template's baked-in
#       credentials, or set vm_enable_ssh_provisioner.
#
# ---------------------------------------------------------------------------
# DO NOT BUMP THE PROVIDER TO 3.0.2-rc09
#
# rc09 passes the whole offline suite and then fails at apply against THIS
# template, deterministically:
#
#   Error: error updating VM: api error: code: 500
#          message: volume V5010-01-1:vm-9101-disk-0.qcow2 does not exist
#
# Template 110's volid carries a .qcow2 extension on an LVM store, which LVM
# cannot represent. rc09 derives the cloned volid from that name instead of
# reading back what Proxmox created (vm-9101-disk-1, raw). rc07 reads it back.
# See docs/provider-versions.md.
# ---------------------------------------------------------------------------
# ============================================================================

module "vm" {
  source = "../../"

  pve_api_url        = var.pve_api_url
  pve_api_user       = var.pve_api_user
  pve_api_password   = var.pve_api_password
  pve_api_tls_verify = var.pve_api_tls_verify # true = TLS-Check AUS, siehe Variable

  # --- placement, all verified against the API on 2026-08-24 ---
  pve_cluster_node = "ul-pve10"   # NOT ul-pve11 (cannot clone), NOT ul-pve01
  pve_datastore    = "V5010-01-1" # LVM, shared across nodes
  pve_folder_path  = "stuttgart-things"
  pve_network      = "vmbrvlan" # the VLAN-aware trunk; vmbr0 is untagged
  vm_vlan_tag      = 101        # what the templates use — the EnvironmentConfig says 102

  vm_name  = "tf-disks-test"
  vm_notes = "built by terraform"

  # Optional. Omit to let Proxmox assign the next free VMID — required if you
  # ever raise vm_count above 1, since all instances would ask for this one.
  vm_id = 9101

  # 110 = sthings-u26. Clone by VMID, not by name: the NAME is what drifted
  # (211 used to be called sthings-u26 too and is not any more).
  vm_clone_id   = 110
  vm_full_clone = true # survives deleting the template

  vm_num_cpus  = 2
  vm_memory    = 4096
  vm_disk_size = "32G"
  vm_bootdisk  = "virtio0" # every LabUL template has its root here

  # REQUIRED for the ip output to ever populate.
  vm_guest_agent = 1

  # --- the cloud-init drive the template does not have ---
  # NFS on purpose. The cidata image is the one disk Proxmox frees and
  # re-allocates on every stop/start, and on V5010-01-1 that round trip orphans
  # an LV that leaves the VM unbootable.
  vm_cloudinit_datastore = "DD-sthings"

  vm_network_address0 = "ip=dhcp"
  vm_ci_os_type       = "cloud-init"
  vm_ci_user          = "sthings"
  vm_ci_password      = var.ci_password
  vm_ci_ssh_keys      = var.ci_ssh_keys

  # Emit our own SMBIOS so PegaProx's SMBIOS Auto-Configurator skips this VM —
  # its needs_smbios_update() leaves any VM that already has SMBIOS keys alone.
  vm_smbios_manufacturer = "stuttgart-things"
  vm_smbios_product      = "terraform-proxmox-vm"

  vm_tags = ["smoketest", "terraform"]

  # Off: cloud-init sets the hostname, so no post-create SSH dependency. Turn
  # it on only if you must bootstrap a template that ignores cloud-init.
  vm_enable_ssh_provisioner = false
}

output "ip" { value = module.vm.ip }
output "vmid" { value = module.vm.vmid }
output "name" { value = module.vm.name }
output "mac" { value = module.vm.mac }
