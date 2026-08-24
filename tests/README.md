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

**C. A template.** Do not take the VMID from any document — including this one.
Query it. The LabUL inventory below was verified against the live API on
**2026-08-24** and had already drifted from every doc that described it:

| VMID | Name | Node | Root disk | cloud-init drive |
|------|------|------|-----------|------------------|
| 110 | `sthings-u26` | ul-pve10 | `virtio0` on V5010-01-1 | none |
| 144 | `ubuntu26-base-os` | ul-pve11 | `virtio0` on DD-sthings | none |
| 192 | `ubuntu26-base-20260728-1419` | ul-pve11 | — | none |
| 211 | `ubuntu26-base-20260731-0909` | ul-pve11 | `virtio0` on DD-sthings | none |

```bash
curl -sk -b "PVEAuthCookie=$PVE_TICKET" "$PVE_HOST/api2/json/cluster/resources?type=vm" \
  | jq '.data[] | select(.template==1) | {name,vmid,node}'
```

What changed against the older notes, and why trusting them costs you an hour:

- **`ubuntu24` no longer exists.** The April test harness in
  `terraform/proxmox-test` still names it; that harness cannot run as written.
- **`sthings-u26` is no longer ambiguous.** It is VMID 110 only. 211 was
  renamed to `ubuntu26-base-20260731-0909`, so the "two templates share a name"
  warning in the `proxmoxvm` EnvironmentConfig comments no longer describes
  reality. Cloning by name would now resolve — but `vm_clone_id` is still the
  right call, because the name is what drifted.
- **NO template carries a cloud-init drive.** All four have `virtio0` and
  nothing else. This is why `vm_cloudinit_datastore` is mandatory for any
  `vm_ci_*` to work here — the module creates the drive, nothing else does.

⚠️ **`ul-pve11` cannot currently build.** Every storage API call on that node
times out (596 after exactly 30 s), and a clone has to resolve the target
storage. Templates 144, 192 and 211 all live there, so **110 on ul-pve10 is the
only usable Linux template right now.** See `docs/labul-ul-pve11-incident.md`.

- **VMID 110 does not run cloud-init.** It ships
  `/etc/cloud/cloud-init.disabled`, so the guest ignores the cidata drive the
  module attaches. The drive is still created (that part is verifiable); the
  guest just will not consume it. For a guest-side cloud-init test you need
  211 — i.e. you need ul-pve11 fixed first.
- **Set `vm_cloudinit_datastore`** to test any `vm_ci_*` variable — the module
  now creates the cidata drive itself. Use the NFS store `DD-sthings`, not
  `V5010-01-1` (which orphans the cidata LV on stop/start). Check the
  template's root disk slot while you are there:
  ```bash
  qm config 110 | grep -E 'ide2|virtio0'
  ```
- **Check for disks the module does not declare** before the first apply on an
  EXISTING VM — undeclared slots are deleted:
  ```bash
  qm config <vmid> | grep -E '^(virtio|scsi|sata|ide)[0-9]+:'
  ```
- **The QEMU guest agent must be installed and enabled**, or `output.ip` stays
  empty forever and `vm_enable_ssh_provisioner` has nothing to connect to.
- **Note the root disk slot.** Every LabUL template is on `virtio0`, not
  `scsi0` — which matches this module's `vm_bootdisk` default.

**D. Placement values.** For LabUL these are already known, from the
`proxmoxvm` EnvironmentConfig:

These are the values a VM was actually built with on 2026-08-24 (VM 9101,
verified and torn down again):

| Terraform | LabUL value |
|-----------|-------------|
| `pve_cluster_node` | `ul-pve10` — **not** ul-pve11, which cannot clone; not ul-pve01, which no longer holds the templates |
| `pve_datastore` | `V5010-01-1` (LVM, shared across nodes) |
| `vm_cloudinit_datastore` | `DD-sthings` (NFS — survives the stop/start that orphans a cidata LV on V5010-01-1) |
| `pve_network` | `vmbrvlan` (VLAN-aware trunk) |
| `vm_vlan_tag` | `101` — what the templates themselves use; the EnvironmentConfig says 102 |
| `pve_folder_path` | `stuttgart-things` |
| `vm_clone_id` | `110` (the only template on a working node) |
| `vm_bootdisk` | `virtio0` (all LabUL templates) |

The full working configuration is committed as
[`examples/09-labul-smoketest`](../examples/09-labul-smoketest/).

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
