# Provider version pin

This module pins `Telmate/proxmox` to an **exact** version in
[`provider.tf`](https://github.com/stuttgart-things/proxmox-vm/blob/main/provider.tf),
not a range. The provider's 3.x line is still shipping release candidates, and
two of them have changed resource behaviour without a major-version bump. A
range would let that reach consumers unannounced.

| | |
|---|---|
| **Current pin** | `3.0.2-rc07` |
| **Blocked** | `3.0.2-rc09` — see [Why rc09 is blocked](#why-rc09-is-blocked) |
| **Skipped** | `3.0.2-rc08` — see [below](#why-rc08-is-skipped) |

!!! danger "Do not bump to rc09"
    rc09 passes the entire offline suite and then **fails at apply** against
    LabUL's only usable Linux template. The bump is parked in
    [PR #44](https://github.com/stuttgart-things/proxmox-vm/pull/44), not
    merged.

## rc07 → rc09

Full schema diff of `proxmox_vm_qemu` between the two versions. **Nothing was
removed and nothing this module sets changed meaning**, which is what made the
bump a mechanical one-line change:

| Change | Attribute | Impact here |
|---|---|---|
| added | `power_state` | none — not used, see [`vm_state` is deprecated](#vm_state-is-deprecated) |
| added | `efidisk.format` | none — optional, not set |
| now computed | `efidisk.efitype` | none — the module always sets it explicitly |
| now computed | `efidisk.pre_enrolled_keys` | none — same |
| now `max_items = 1` | `efidisk` | none — the module emits at most one |
| deprecated | `vm_state` | none — not used |

Reproduce it with:

```bash
terraform providers schema -json \
  | jq '.provider_schemas["registry.terraform.io/telmate/proxmox"]
        .resource_schemas.proxmox_vm_qemu.block'
```

## Why rc09 is blocked

The schema diff above is clean, the offline suite is entirely green, and rc09
still cannot build a VM here. This is the whole argument for the two-stage
verification below.

### The failure

Cloning template **110** (`sthings-u26`, the only Linux template this project
can currently use) fails after roughly 90 seconds:

```
Error: error updating VM: api error: code: 500
       message: volume V5010-01-1:vm-9101-disk-0.qcow2 does not exist
```

Reproduced twice, deterministically, on 2026-08-25. The identical
configuration on rc07 applies cleanly, returns an IP, and plans empty on the
second run.

### The cause

rc09 **derives** the post-clone volume ID from the template's own volume ID
instead of reading back what Proxmox actually created. rc07 reads it back.

Template 110's root disk is:

```
virtio0  V5010-01-1:vm-110-disk-0.qcow2,cache=none,replicate=0,size=16G
```

Cloning it to VM 9101, rc09 addresses `V5010-01-1:vm-9101-disk-0.qcow2` in its
follow-up update. Proxmox created `V5010-01-1:vm-9101-disk-1` — a different
index *and* no extension — so the update names a volume that never existed.

!!! warning "This is a storage-class incompatibility, not one bad template"
    An earlier revision of this page called template 110's volume ID
    "malformed" and suggested rebuilding the template as a fix. **That was
    wrong, and rebuilding would not help.**

    `V5010-01-1` is LVM with **`snapshot-as-volume-chain: 1`** — the Proxmox 9
    feature where LVM holds *qcow2-formatted* volumes so snapshots can be
    expressed as volume chains. On that storage the `.qcow2` suffix is the
    norm, not an anomaly:

    ```
    volumes on V5010-01-1:   .qcow2 = 114     no extension = 11
    ```

    A freshly built template lands there the same way, so a Packer rebuild
    produces another `.qcow2` volume ID and changes nothing. The exposure is
    every clone of any of those 114 volumes, not one template.

    Templates 144, 192, 211 and 996 escape only because they sit on the NFS
    store `DD-sthings` and carry `base-<vmid>-disk-0.raw` — a different
    storage, not a better template.

### Second rc09 issue: `vm_state` drift

Planning rc09 against a VM that rc07 built produces a non-empty plan:

```
~ resource "proxmox_vm_qemu" "proxmox_vm" {
    - vm_state = "running" -> null
  }
```

`vm_state` is deprecated in favour of `power_state`, and this module declares
neither. Every pre-existing VM would show this diff on the first plan after
the bump.

### What a fix needs

**Upstream has to read the cloned volume ID back**, the way rc07 does. There is
no configuration-side workaround and nothing to fix on the Proxmox side:
`snapshot-as-volume-chain` is a supported storage layout, and a provider that
predicts volume IDs rather than reading them will keep breaking on it.

Rebuilding template 110 does **not** qualify, for the reason in the warning
above — the new template would land on the same storage with the same naming.

A rebuild is still worth doing, but for an unrelated reason: 110 ships
`/etc/cloud/cloud-init.disabled`, so the guest ignores the cloud-init drive
this module now creates correctly. That is a template problem. The volume ID
is not.

### Why rc08 is skipped

rc08 refactored the EFI disk
([#1503](https://github.com/Telmate/terraform-provider-proxmox/pull/1503)) and
inverted the `automatic_reboot` guardrail. The rc09 release notes describe
themselves as addressing *"the major issues introduced by v3.0.2-rc08"*, so
rc08 is a version to move **through**, never to sit on.

### `vm_state` is deprecated

rc08 added `power_state`
([#1513](https://github.com/Telmate/terraform-provider-proxmox/pull/1513)) and
rc09 marks `vm_state` deprecated. This module exposes **neither**, so nothing
breaks today — but a future `vm_power_state` variable should be wired to
`power_state`, not to `vm_state`.

### Network changes that the module absorbs

rc08 changed two network semantics:

- `rate` is now MBps, not MB/s-over-8
  ([#1478](https://github.com/Telmate/terraform-provider-proxmox/pull/1478))
- `network.id` gained a `net` prefix
  ([#1491](https://github.com/Telmate/terraform-provider-proxmox/pull/1491))

Neither surfaces here: the module does not expose `rate`, and `network` sits in
`ignore_changes` (see the note in [`vm.tf`](https://github.com/stuttgart-things/proxmox-vm/blob/main/vm.tf)).

## Verifying a bump

A provider bump is not done until both stages pass. The offline stage catches
schema breakage; only the live stage catches drift, because a perpetual diff is
invisible until real Proxmox state is read back.

```bash
# stage 1 — offline
terraform init -upgrade && terraform validate && terraform test
for d in examples/0*/; do (cd "$d" && terraform init -backend=false && terraform validate); done

# stage 2 — live, against a real node
cd tests && terraform plan -var-file=smoke.tfvars   # must be empty on the second run
```

See [`tests/README.md`](https://github.com/stuttgart-things/proxmox-vm/blob/main/tests/README.md)
for the smoke-test setup. Both perpetual diffs this module has ever had
(`bootdisk`, `startup_shutdown`) were found in stage 2 and were invisible in
stage 1.
