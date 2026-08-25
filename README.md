# stuttgart-things/proxmox-vm

Terraform module for creating Proxmox virtual machines based on the [Telmate/proxmox](https://registry.terraform.io/providers/Telmate/proxmox/latest) provider (v3.x).

| | |
|---|---|
| Documentation | [stuttgart-things.github.io/proxmox-vm](https://stuttgart-things.github.io/proxmox-vm/) |
| Provider pin | `3.0.2-rc07`, exact. **Do not bump to rc09** — it passes every offline check and then fails at apply. [Why](docs/provider-versions.md#why-rc09-is-blocked) |

## Usage

Runnable, annotated examples live in [`examples/`](examples/) — start with
[`01-minimal`](examples/01-minimal/) or, if you are porting from the Crossplane
`NativeProxmoxVM` XR, [`06-labul-kind`](examples/06-labul-kind/).

```hcl
module "proxmox-vm" {
  source             = "git::https://github.com/stuttgart-things/proxmox-vm.git"
  pve_api_url        = var.pve_api_url
  pve_api_user       = var.pve_api_user
  pve_api_password   = var.pve_api_password
  pve_api_tls_verify = var.pve_api_tls_verify
  pve_cluster_node   = "sthings-pve1"
  pve_datastore      = "datastore"
  pve_folder_path    = "stuttgart-things"
  pve_network        = "vmbr101"
  vm_count           = 1
  vm_name            = "my-vm"
  vm_notes           = "created by terraform"
  vm_template        = "ubuntu22"
  vm_num_cpus        = 4
  vm_memory          = 4096
  vm_disk_size       = "32G"
}

output "ip" {
  value = module.proxmox-vm.ip
}
```

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `pve_api_url` | string | - | URL of Proxmox API |
| `pve_api_user` | string | - | Proxmox API username |
| `pve_api_password` | string | - | Proxmox API password |
| `pve_api_tls_verify` | bool | `true` | **Inverted name** — wired to `pm_tls_insecure`, so `true` *disables* certificate checking |
| `pve_cluster_node` | string | - | Proxmox cluster node name |
| `pve_datastore` | string | - | Proxmox datastore name |
| `pve_folder_path` | string | - | VM folder/pool path |
| `pve_network` | string | - | Proxmox network bridge |
| `vm_count` | number | `1` | Number of VMs (1-5) |
| `vm_name` | string | - | VM name |
| `vm_notes` | string | - | VM description |
| `vm_template` | string | - | Template to clone from |
| `vm_num_cpus` | number | `2` | CPU cores (2,4,6,8,10,12,16) |
| `vm_num_sockets` | number | `1` | CPU sockets |
| `vm_memory` | number | `4096` | Memory in MB (1024,2048,4096,8192) |
| `vm_disk_size` | string | `"32G"` | Disk size — one of 20G, 32G, 48G, 64G, 80G, 96G, 100G, 128G, 160G, 196G, 200G, 256G, 320G, 512G, 1024G |
| `vm_bootdisk` | string | `"virtio0"` | Boot disk slot. **Now validated** — `virtio0/1`, `scsi0/1`, `sata0/1`, `ide0/1`. Must match the template's root disk slot. |
| `vm_storage_controller` | string | `"virtio-scsi-pci"` | SCSI controller type |
| `vm_firmware` | string | `"seabios"` | BIOS firmware |
| `vm_os_type` | string | `"l26"` | Guest OS type |
| `vm_guest_agent` | number | `1` | QEMU guest agent (0/1) |
| `vm_numa` | bool | `true` | Enable NUMA |
| `vm_onboot` | bool | `true` | Start VM on node boot |
| `vm_network_type` | string | `"virtio"` | Network card model |
| `vm_network_address0` | string | `"ip=dhcp"` | IP config for cloud-init |
| `vm_macaddr` | string | `null` | MAC address (optional) |
| `vm_vlan_tag` | number | `-1` | VLAN tag for the NIC (e.g. on `vmbrvlan`); `-1` = untagged, valid `2`-`4094` |
| `vm_ssh_user` | string | `""` | SSH username for the bootstrap provisioner |
| `vm_ssh_password` | string | `""` | SSH password for the bootstrap provisioner |

### Opt-in variables

Every variable below defaults to `null`/`false` and renders the resource
byte-identically to a module without it. Nothing here touches an existing VM
until you set it. The one exception is `vm_enable_ssh_provisioner` — see
[Behaviour change](#behaviour-change-the-ssh-bootstrap-is-now-opt-in).

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `vm_clone_id` | number | `null` | Clone by template **VMID** instead of by name. Mutually exclusive with `vm_template`. Forces replacement. |
| `vm_full_clone` | bool | `null` | Full clone vs linked clone. Unset = provider default (full). Forces replacement. |
| `vm_id` | number | `null` | Pin the new VM's VMID. Unset lets Proxmox assign one. Set only before first create. |
| `vm_tags` | list(string) | `null` | Proxmox tags. Pass them lowercase and sorted — Proxmox normalises server-side and you will otherwise get a perpetual diff. |
| `vm_cpu_type` | string | `null` | CPU model, e.g. `host`, `x86-64-v2-AES`. `host` blocks live migration across differing CPUs. |
| `vm_balloon` | number | `null` | Balloon minimum in MiB. Must be ≤ `vm_memory`. Unset pins memory. |
| `vm_ci_user` | string | `null` | Cloud-init user (`ciuser`). **Every `vm_ci_*` field needs `vm_cloudinit_datastore`** — without a cidata drive Proxmox silently ignores all of them. |
| `vm_ci_password` | string | `null` | Cloud-init password (`cipassword`). Set it whenever `vm_ci_user` is set — see below. |
| `vm_ci_ssh_keys` | list(string) | `null` | Authorized public keys, one per element; joined with newlines for the provider. |
| `vm_ci_upgrade` | bool | `null` | Package upgrade on first boot (`ciupgrade`). |
| `vm_ci_nameserver` | string | `null` | DNS servers — **space**-separated in one string, not comma. |
| `vm_ci_searchdomain` | string | `null` | DNS search domain. |
| `vm_ci_os_type` | string | `null` | Telmate `os_type` (`cloud-init`, `ubuntu`, `centos`). **Not** the same field as `vm_os_type`, which is `qemu_os`. |
| `vm_network_firewall` | bool | `null` | Proxmox firewall on the NIC. |
| `vm_network_mtu` | number | `null` | NIC MTU; `1` inherits from the bridge. |
| `vm_smbios_manufacturer` | string | `null` | SMBIOS manufacturer. Setting either SMBIOS field emits the block. Forces replacement. |
| `vm_smbios_product` | string | `null` | SMBIOS product. |
| `vm_efi_disk_storage` | string | `null` | Datastore for the EFI vars disk. **Required with `vm_firmware = "ovmf"`.** |
| `vm_efi_disk_type` | string | `"4m"` | EFI vars disk type — `2m` or `4m`. Only used when `vm_efi_disk_storage` is set. |
| `vm_efi_disk_pre_enrolled_keys` | bool | `false` | Pre-enroll Microsoft Secure Boot keys. Refuses unsigned kernels/modules. |
| `vm_cloudinit_datastore` | string | `null` | Datastore for the cloud-init (cidata) drive. **This is what makes every `vm_ci_*` variable work.** Pick a store that survives a stop/start. |
| `vm_cloudinit_slot` | string | `"ide2"` | Slot for that drive — `ide0`-`ide3`. Must not collide with `vm_bootdisk`. |
| `vm_disk_format` | string | `null` | Root disk format — `raw`, `qcow2`, `vmdk`. What a block store accepts depends on the store: plain LVM/ZFS/Ceph take `raw`, but LVM with Proxmox 9's `snapshot-as-volume-chain` holds `qcow2`. Check the store rather than assuming. |
| `vm_disk_cache` | string | `null` | Cache mode. `unsafe` discards flushes and corrupts the guest on host power loss. |
| `vm_disk_iothread` | bool | `null` | Dedicated I/O thread. **scsi/virtio only**, and Proxmox only honours it on `virtio-scsi-single`. |
| `vm_disk_discard` | bool | `null` | Pass guest TRIM through to thin-provisioned storage. |
| `vm_disk_emulate_ssd` | bool | `null` | Advertise as SSD. **ide/sata/scsi only** — not available on virtio. |
| `vm_disk_backup` | bool | `null` | Include the root disk in vzdump backups. |
| `vm_disk_replicate` | bool | `null` | Include the root disk in storage replication. |
| `vm_enable_ssh_provisioner` | bool | `false` | Run the legacy post-create SSH bootstrap. |
| `vm_ssh_private_key` | string | `null` | PEM private key for that bootstrap, instead of `vm_ssh_password`. |
| `vm_bootstrap_reset_machine_id` | bool | `false` | Regenerate `/etc/machine-id` during the bootstrap. **Changes the VM's IP** — the DHCP client id is derived from it — which makes the `ip` output stale. Only with `vm_enable_ssh_provisioner`. |

## Outputs

| Name | Description |
|------|-------------|
| `ip` | IPv4 addresses of created VMs (needs `vm_guest_agent = 1`) |
| `ipv6` | IPv6 addresses, when the guest agent reports one |
| `mac` | MAC addresses of created VMs |
| `id` | Provider resource IDs, `<node>/qemu/<vmid>` |
| `vmid` | Proxmox VMIDs, as numbers |
| `name` | VM names, in count order |

## Proxmox API Discovery

Before using this module, gather available resources from the Proxmox API:

```bash
export PVE_HOST="https://your-pve-host:8006"
export PVE_TICKET=$(curl -sk \
  -d "username=user@realm&password=secret" \
  "$PVE_HOST/api2/json/access/ticket" | jq -r '.data.ticket')

# Cluster nodes (pve_cluster_node)
curl -sk -b "PVEAuthCookie=$PVE_TICKET" "$PVE_HOST/api2/json/nodes" | jq -r '.data[].node'

# VM templates (vm_template)
curl -sk -b "PVEAuthCookie=$PVE_TICKET" "$PVE_HOST/api2/json/cluster/resources?type=vm" \
  | jq '.data[] | select(.template==1) | {name,vmid,node}'

# Datastores (pve_datastore)
curl -sk -b "PVEAuthCookie=$PVE_TICKET" "$PVE_HOST/api2/json/storage" \
  | jq -r '.data[] | "\(.storage) (\(.type))"'

# Network bridges (pve_network)
curl -sk -b "PVEAuthCookie=$PVE_TICKET" "$PVE_HOST/api2/json/nodes/<node>/network" \
  | jq -r '.data[] | select(.type=="bridge") | .iface'

# Resource pools (pve_folder_path)
curl -sk -b "PVEAuthCookie=$PVE_TICKET" "$PVE_HOST/api2/json/pools" | jq -r '.data[].poolid'
```

See the full [Proxmox API Discovery](docs/proxmox-api-discovery.md) guide for details.

## Crossplane Usage

This module can be used with the [Upbound Terraform Provider](https://marketplace.upbound.io/providers/upbound/provider-terraform/) for Crossplane.
A fuller, annotated Workspace — including the string-only `vars` trap — is in
[`examples/08-crossplane-workspace`](examples/08-crossplane-workspace/).

> **`spec.forProvider.vars` sends every value as a string.** Numbers and bools
> are fine (Terraform coerces them), but **list** variables such as `vm_tags`
> and `vm_ci_ssh_keys` are not — pass those via `varFiles`, or the apply fails
> with `Inappropriate value for attribute`.

If you want reconcile-loop drift correction, per-field status and the
`AnsibleRun` hand-off instead, use the native `NativeProxmoxVM` XR
(provider-proxmox-bpg) rather than wrapping Terraform.
[`examples/06-labul-kind`](examples/06-labul-kind/) maps the two field by field.

```yaml
apiVersion: tf.upbound.io/v1beta1
kind: Workspace
metadata:
  name: appserver
spec:
  providerConfigRef:
    name: terraform-default
  forProvider:
    source: Remote
    module: git::https://github.com/stuttgart-things/proxmox-vm.git
    vars:
      - key: vm_count
        value: "1"
      - key: vm_name
        value: appserver
      - key: vm_template
        value: ubuntu22
      - key: vm_num_cpus
        value: "4"
      - key: vm_memory
        value: "4096"
      - key: vm_disk_size
        value: 128G
      - key: pve_network
        value: vmbr103
      - key: pve_datastore
        value: v3700
      - key: pve_folder_path
        value: stuttgart-things
      - key: pve_cluster_node
        value: sthings-pve1
    varFiles:
      - source: SecretKey
        secretKeyRef:
          namespace: default
          name: pve-tfvars
          key: terraform.tfvars
```



## Breaking change: `disk` → `disks`

The module now uses Telmate's `disks` block instead of the legacy `disk` block.
**This does not destroy your VM** — there is no `ForceNew` anywhere in the
provider's disk package, so the switch is an in-place update.

**Why it had to happen:** the two blocks conflict at the schema level, and only
`disks` can configure a cloud-init drive. While the module used `disk`, every
`vm_ci_*` variable was accepted and silently ignored.

**And it fixes a data-loss bug.** Both blocks build their request by marking
*every* slot for deletion and then filling in what the config declares. A
template that shipped a cidata drive on `ide2` therefore had it **deleted on
the first apply**, because the old config declared only `virtio0`. That, not a
missing field, is why cloud-init never worked here.

**What you have to do:**

1. Check the VM does not carry a disk this module does not declare —
   `qm config <vmid> | grep -E '^(virtio|scsi|sata|ide)[0-9]+:'`
2. Set `vm_cloudinit_datastore` if you want cloud-init.
3. Make sure `vm_bootdisk` is one of the validated slots.
4. `terraform plan` and confirm it reports `~` (update in place), not `-/+`.

Full detail, including what a healthy plan looks like and the Crossplane
rollout: **[docs/migration-disks.md](docs/migration-disks.md)**.

## Bug fix: the SSH bootstrap no longer reboots the VM

**If you enabled `vm_enable_ssh_provisioner` before, it failed every apply.**
This is fixed.

The bootstrap used to write `/etc/hostname`, regenerate the machine-id, reboot,
and then reconnect. The reconnect could never succeed:

> systemd-networkd derives its default DHCPv4 client identifier from
> `/etc/machine-id`. Regenerating it changes the DHCP identity, so **the VM
> comes back on a different IP** — while Terraform reconnects to
> `default_ipv4_address`, captured at create time. It blocks until the 5 minute
> connection timeout and `terraform apply` exits 1.

Measured on a live cluster on 2026-08-25: four consecutive applies, ~8m20s each
(~3 min to build the VM plus the 5 min timeout), with the address change
confirmed in the guest journal (`10.31.101.131` → `.132`, `.134` → `.136`).

The quieter half: even with a working reconnect, the **`ip` output would still
be the create-time address**. A DNS record or an IP reservation taken from it
would point at an address nobody answers on, while every stage before it
reported success.

The bootstrap now runs a single `hostnamectl set-hostname` — applied
immediately, persisted, no reboot, no reconnect, lease untouched. The
machine-id reset is available as
[`vm_bootstrap_reset_machine_id`](#opt-in-variables) and defaults to **false**;
turning it on still moves the VM's address, so only do it when nothing consumes
the `ip` output.

## Behaviour change: the SSH bootstrap is now opt-in

The post-create SSH bootstrap used to run unconditionally on every create. It
is now behind `vm_enable_ssh_provisioner`, which defaults to **false**.

**To keep the old behaviour**, add one line:

```hcl
vm_enable_ssh_provisioner = true
vm_ssh_user               = var.vm_ssh_user
vm_ssh_password           = var.vm_ssh_password
```

**Existing VMs are unaffected either way.** A `remote-exec` provisioner only
ever runs at create time, and provisioners are not tracked as resource
attributes — so moving the block out of `proxmox_vm_qemu` produces no diff, and
with the flag false the new `terraform_data.bootstrap` is not created at all.

**Prefer leaving it off.** The provisioner is a hard dependency of
`terraform apply`: no reachable SSH — wrong credentials, no DHCP lease yet, a
firewall in the way, sshd not up — fails the apply *after* the VM already
exists, leaving a tainted resource that the next apply destroys and recreates.
[`examples/02-cloud-init`](examples/02-cloud-init/) gets you the same hostname
with none of that, because Proxmox writes it into the generated cloud-init
user-data from the VM name.

## Bug fix: `vm_vlan_tag = -1` no longer breaks the plan

`vm_vlan_tag` was wired directly to the provider's `network.tag`, but Telmate
v3 validates `tag >= 0` and rejects the `-1` "untagged" default:

```
Error: tag must be equal or greater than 0, got: -1
```

Since `-1` is the variable's default, **every** apply that did not set a VLAN
failed at plan time. `-1` is now treated as a module-level sentinel and the
attribute is omitted entirely, which is what actually means "no VLAN tag". The
variable's contract is unchanged.

## Verified against a live cluster

The `disks` migration was smoke-tested end to end on LabUL (2026-08-24, VM 9101
on `ul-pve10`, cloned from template 110 `sthings-u26`):

```
ide2      DD-sthings:9101/vm-9101-cloudinit.raw,media=cdrom
virtio0   V5010-01-1:vm-9101-disk-1,replicate=0,size=32G
ciuser    sthings
smbios1   uuid=…,manufacturer=c3R1dHRnYXJ0LXRoaW5ncw==,product=…
tags      smoketest;terraform
net0      virtio=BC:24:11:51:C7:9F,bridge=vmbrvlan,tag=101
```

The template carries **no** cloud-init drive — `ide2` above was created by the
module. That is precisely what the legacy `disk` block could not do. A second
`terraform plan` reports `No changes.`

Two perpetual diffs surfaced only in that live run and are fixed here:

- **`bootdisk` is no longer declared.** The provider does write it back, but
  as an empty string — modern Proxmox has no legacy `bootdisk` field and
  expresses boot order as `boot: order=virtio0;net0`. State got `""` while the
  config insisted on `"virtio0"`, so every plan wanted to add it again.
- **`startup_shutdown` is ignored.** The provider returns a block of `-1`
  defaults that the module never declares, so every plan wanted to remove it.

## Known warts

Kept as-is because fixing them would break existing callers. Documented so they
stop costing debugging sessions.

- **`pve_api_tls_verify` is inverted.** It is wired to the provider's
  `pm_tls_insecure`, so `true` — the default — *disables* certificate
  checking. Set it to `false` to actually verify.
- **String variables default to the bool `false`**, which Terraform coerces to
  the string `"false"`. That is the module's "unset" marker, which is why
  `vm_template` has to be compared against `"false"` rather than `null`.
- **Network changes are ignored after create.** The resource carries
  `lifecycle { ignore_changes = [network] }`, and `ignore_changes` only accepts
  literals, so this cannot be made configurable. `vm_vlan_tag`, `vm_macaddr`,
  `vm_network_firewall` and `vm_network_mtu` therefore take effect on **create
  only** — changing one on a live VM is silently dropped. Adjust it in Proxmox,
  or taint the VM.
- **The `disks` block is authoritative.** Any slot it does not declare is sent
  to Proxmox with `delete=1` — a no-op on an empty slot, a **removal** on an
  occupied one. The module declares exactly one data disk plus an optional
  cidata drive, so a second disk you added by hand in the Proxmox UI **will be
  removed on the next apply**. This is not new (the legacy `disk` block did the
  same), but check with
  `qm config <vmid> | grep -E '^(virtio|scsi|sata|ide)[0-9]+:'` before your
  first apply after upgrading.
- **`vm_count` naming is asymmetric.** The first VM keeps the bare name, later
  ones get a 1-based suffix: `worker`, `worker-2`, `worker-3`. Changed only if
  you are willing to rename every existing VM.

## Testing

Provider-mocked unit tests cover the default rendering, every opt-in feature
and every guardrail. No Proxmox cluster and no credentials required:

```bash
terraform init
terraform test
```

`tests/defaults.tftest.hcl` is the one that matters most: it asserts that with
no opt-in variable set, the resource renders exactly as it did before they
existed.

## License

BSD

## Author Information

stuttgart-things
