# Testing

Two levels. The first needs nothing at all; the second needs a real cluster.

---

## 1. Offline — unit tests (no Proxmox, no credentials)

```bash
terraform init
terraform test
```

17 runs across two files, using `mock_provider "proxmox"`. No API call is made,
so this is safe to run anywhere, including CI without secrets.

| File | Covers |
|------|--------|
| `defaults.tftest.hcl` | That with **no** opt-in variable set the resource renders exactly as it did before they existed — plus `vm_count` naming and the widened disk list. |
| `optin.tftest.hcl` | Each opt-in feature (cloud-init, clone-by-VMID, UEFI, SMBIOS, bootstrap) and every guardrail (preconditions, variable validation, `check` blocks). |
| `storage.tftest.hcl` | The `disks` block: cidata drive, slot routing across all four buses, per-bus attribute limits, and the collision guardrails. |

Note that provider **schema validation still runs** under `mock_provider` — that
is how the `vm_vlan_tag = -1` bug surfaced. Fake values that the provider parses
(SSH public keys, VLAN tags) must be genuinely well-formed.

Run one file, or one case:

```bash
terraform test -filter=tests/optin.tftest.hcl
terraform test -verbose
```

---

## 2. Online — smoke test against a real Proxmox

### What you need

**A. API access**

| Value | Variable | Note |
|-------|----------|------|
| API URL | `pve_api_url` | Must include the path: `https://<host>:8006/api2/json` |
| API user | `pve_api_user` | Realm included: `terraform@pve`, `root@pam` |
| API password | `pve_api_password` | Telmate is wired for user/password here, not an API token |
| TLS | `pve_api_tls_verify` | **Inverted** — `true` (default) *disables* checking. Leave `true` for self-signed cluster certs. |

**B. Proxmox privileges** on the target pool/datastore. A clone that 403s
usually means one of these is missing rather than anything wrong in Terraform:

```
VM.Allocate  VM.Clone  VM.Config.*  VM.Monitor  VM.Audit  VM.PowerMgmt
Datastore.AllocateSpace  Datastore.Audit
Pool.Allocate          # only if you set pve_folder_path
SDN.Use                # only if you set vm_vlan_tag on an SDN-managed bridge
```

Proxmox resolves the **deepest matching ACL path**, so a grant at `/` does not
rescue a more specific deny further down.

**C. A template**, and this is where the traps are:

- **Its VMID, not just its name.** In LabUL *two* templates are called
  `sthings-u26` (110 and 211), so `vm_template = "sthings-u26"` is ambiguous —
  use `vm_clone_id`. This is exactly the case `vm_clone_id` was added for.
- **VMID 110 is the wrong one.** It ships `/etc/cloud/cloud-init.disabled`, so
  cloud-init never runs and every clone keeps the template's hostname. Use
  **211**, which removes the file in its provisioner.
- **Set `vm_cloudinit_datastore`** to test any `vm_ci_*` variable — the module
  now creates the cidata drive itself. Use the NFS store `DD-sthings`, not
  `V5010-01-1` (which orphans the cidata LV on stop/start). Check the
  template's root disk slot while you are there:
  ```bash
  qm config 211 | grep -E 'ide2|virtio0'
  ```
- **Check for disks the module does not declare** before the first apply on an
  EXISTING VM — undeclared slots are deleted:
  ```bash
  qm config <vmid> | grep -E '^(virtio|scsi|sata|ide)[0-9]+:'
  ```
- **The QEMU guest agent must be installed and enabled**, or `output.ip` stays
  empty forever and `vm_enable_ssh_provisioner` has nothing to connect to.
- **Note the root disk slot.** `sthings-u26` is on `virtio0`, not `scsi0` —
  which happens to match this module's `vm_bootdisk` default.

**D. Placement values.** For LabUL these are already known, from the
`proxmoxvm` EnvironmentConfig:

| Terraform | LabUL value |
|-----------|-------------|
| `pve_cluster_node` | `ul-pve11` (**not** `ul-pve01` — the rebuild moved the ubuntu26 templates) |
| `pve_datastore` | `V5010-01-1` |
| `pve_network` | `vmbrvlan` (VLAN-aware trunk) |
| `vm_vlan_tag` | `102` (10.31.102.0/24) |
| `pve_folder_path` | `stuttgart-things` |
| `vm_clone_id` | `211` |

### Running it

```bash
cd examples/06-labul-kind
cp ../../tests/smoke.tfvars.example ./smoke.tfvars   # then fill it in
terraform init
terraform plan  -var-file=smoke.tfvars      # inspect BEFORE applying
terraform apply -var-file=smoke.tfvars
terraform destroy -var-file=smoke.tfvars    # always clean up
```

`smoke.tfvars` is gitignored (`*.tfvars`, with only `*.tfvars.example` allowed
through).

### What to actually check afterwards

| Check | How | Why it matters |
|-------|-----|----------------|
| VM exists with the right VMID | `qm config <vmid>` | `vm_id` / `vm_clone_id` wiring |
| Untagged case does not fail the plan | `terraform plan` with `vm_vlan_tag` unset | This is the **regression test for the `-1` bug** — it failed on `main` |
| Tagged case lands on the right VLAN | `qm config <vmid> \| grep net0` | expect `tag=102` |
| IP is reported back | `terraform output ip` | guest agent actually working |
| Hostname | `ssh … hostname` | cloud-init wrote it, no SSH provisioner needed |
| cloud-init user + keys | `ssh sthings@<ip>` | `vm_ci_user` / `vm_ci_ssh_keys` |
| Password not locked | `sudo passwd -S sthings` | must **not** be `L` — see `vm_ci_password` |
| SMBIOS | `qm config <vmid> \| grep smbios1` | PegaProx opt-out took effect |
| cidata drive exists | `qm config <vmid> \| grep ide2` | expect `media=cdrom`; the `disks` migration |
| Idempotency | `terraform plan` again | must report **no changes** |

That last one is the most valuable single check: a perpetual diff (usually from
`vm_tags` ordering or a Proxmox-normalised value) only shows up on the second
plan.

### Deliberately not covered

`vm_enable_ssh_provisioner` is best tested **last and separately** — a failure
leaves a tainted resource, which is the whole reason it moved into its own
`terraform_data`. Use `examples/07-legacy-ssh-bootstrap` for that.
