resource "proxmox_vm_qemu" "proxmox_vm" {
  target_node        = var.pve_cluster_node
  pool               = var.pve_folder_path
  start_at_node_boot = var.vm_onboot
  count              = var.vm_count
  name               = count.index > 0 ? "${var.vm_name}-${count.index + 1}" : var.vm_name
  description        = var.vm_notes
  clone              = var.vm_template
  bios               = var.vm_firmware
  ipconfig0          = var.vm_network_address0
  memory             = var.vm_memory
  scsihw             = var.vm_storage_controller
  bootdisk           = var.vm_bootdisk
  agent              = var.vm_guest_agent
  qemu_os            = var.vm_os_type

  cpu {
    cores   = var.vm_num_cpus
    sockets = var.vm_num_sockets
    numa    = var.vm_numa
  }

  disk {
    size    = var.vm_disk_size
    slot    = var.vm_bootdisk
    storage = var.pve_datastore
  }

  network {
    id      = 0
    model   = var.vm_network_type
    bridge  = var.pve_network
    macaddr = var.vm_macaddr
    tag     = var.vm_vlan_tag
  }

  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  connection {
    type     = "ssh"
    host     = self.default_ipv4_address
    user     = var.vm_ssh_user
    password = var.vm_ssh_password
    agent    = false
  }

  provisioner "remote-exec" {
    inline = [
      "sudo echo '${count.index > 0 ? "${var.vm_name}-${count.index + 1}" : var.vm_name}' | sudo tee /etc/hostname",
      "sudo systemd-machine-id-setup",
      "sudo shutdown -r +0"
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "echo 'wait for reboot'"
    ]
  }
}
