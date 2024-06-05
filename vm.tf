resource "proxmox_vm_qemu" "proxmox_vm" {
  count       = var.vm_count
  name        = count.index > 0 ? "${var.vm_name}-${count.index + 1}" : var.vm_name
  target_node = var.pve_cluster_node
  clone       = var.vm_template
  pool        = var.pve_folder_path
  numa        = var.vm_numa
  onboot      = var.vm_onboot
  agent       = var.vm_guest_agent
  bios        = var.vm_firmware
  boot        = "order=scsi0;net0"
  cores       = var.vm_num_cpus
  sockets     = var.vm_num_sockets
  memory      = var.vm_memory
  scsihw      = var.vm_storage_controller
  qemu_os     = var.vm_os_type
  description = var.vm_notes

  disks {
    virtio {
      virtio0 {
        disk {
          size = var.vm_disk_size
          storage = var.pve_datastore
          type = var.vm_disk_type
        }
      }
    }
  }

  network {
    model   = var.vm_network_type
    bridge  = var.pve_network
    macaddr = var.vm_macaddr
    tag     = -1
    firewall = false
    rate    = 0
    queues  = 1
    link_down = false
  }

  lifecycle {
    ignore_changes = [
      disk,
      network,
    ]
  }
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
    when    = "create"
    inline  = ["echo 'Waiting for VM to reboot'"]
    on_failure = continue
  }
