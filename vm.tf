resource "proxmox_vm_qemu" "proxmox_vm" {
  target_node       = var.pve_cluster_node
  pool              = var.pve_folder_path
  numa              = var.vm_numa
  count             = var.vm_count
  name              = count.index > 0 ? "${var.vm_name}-${count.index + 1}" : var.vm_name
  desc              = var.vm_notes
  clone             = var.vm_template
  bios              = var.vm_firmware
  os_type           = var.vm_provisioning_method
  ipconfig0         = var.vm_network_address0
  cores             = var.vm_num_cpus
  sockets           = var.vm_num_sockets
  memory            = var.vm_memory
  scsihw            = var.vm_storage_controller
  bootdisk          = var.vm_bootdisk
  agent             = var.vm_guest_agent
  qemu_os           = var.vm_os_type
 # preprovision      = true
  disk {
    size            = var.vm_disk_size
    type            = var.vm_disk_type
    storage         = var.pve_datastore
  }
  network {
    model           = var.vm_network_type
    bridge          = var.pve_network
  }
  lifecycle {
    ignore_changes  = [
      network,
    ]
  }

  connection {
    type     = "ssh"
    host     = self.ssh_host
    user     = var.vm_ssh_user
    password = var.vm_ssh_password
  }
  provisioner "remote-exec" {
    inline = [
      "sudo echo '${count.index > 0 ? "${var.vm_name}-${count.index + 1}" : var.vm_name}' | sudo tee /etc/hostname",
      "sudo systemd-machine-id-setup",
      "domain=$(cat /etc/resolv.conf | grep search | grep -v con | awk '{print $2}')",
      "host=$(hostname)",
      "sudo sed -i '/^127/d' /etc/hosts && sudo sed -i '/^#/d' /etc/hosts",
      "echo '127.0.0.1' $${host} $${host}'.'$${domain}' localhost' | sudo tee /etc/hosts",
      "sudo reboot -f"
    ]
    on_failure = continue
  }
}
