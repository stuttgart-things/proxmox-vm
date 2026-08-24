# Proxmox API credentials. Keep them out of the repo: pass them via a tfvars
# file that is gitignored, or via TF_VAR_pve_api_password et al.

variable "pve_api_url" {
  type        = string
  description = "e.g. https://pve.example.com:8006/api2/json"
}

variable "pve_api_user" {
  type        = string
  description = "e.g. root@pam or terraform@pve"
}

variable "pve_api_password" {
  type      = string
  sensitive = true
}

variable "pve_api_tls_verify" {
  type    = bool
  default = true
}
