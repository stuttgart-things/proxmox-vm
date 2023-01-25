resource "proxmox_vm_qemu" "proxmox_vm" {
  target_node = var.pve_cluster_node
  pool        = var.pve_folder_path
  numa        = var.vm_numa
  onboot      = var.onboot
  count       = var.vm_count
  name        = count.index > 0 ? "${var.vm_name}-${count.index + 1}" : var.vm_name
  desc        = var.vm_notes
  clone_wait  = 45
  clone       = var.vm_template
  bios        = var.vm_firmware
  ipconfig0   = var.vm_network_address0
  cores       = var.vm_num_cpus
  sockets     = var.vm_num_sockets
  memory      = var.vm_memory
  scsihw      = var.vm_storage_controller
  bootdisk    = var.vm_bootdisk
  agent       = var.vm_guest_agent
  qemu_os     = var.vm_os_type
  disk {
    size    = var.vm_disk_size
    type    = var.vm_disk_type
    storage = var.pve_datastore
  }
  network {
    model   = var.vm_network_type
    bridge  = var.pve_network
    macaddr = var.vm_macaddr
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
