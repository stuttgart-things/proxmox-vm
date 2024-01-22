terraform {
  required_version = ">= 1.5.5"

  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = ">= 2.9.14"
    }
  }
}

provider "proxmox" {
  pm_api_url  = var.pve_api_url 
  pm_user     = var.pve_api_user
  pm_password = var.pve_api_password
}

