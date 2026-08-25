# Provider version pin

This module pins `Telmate/proxmox` to an **exact** version in
[`provider.tf`](https://github.com/stuttgart-things/proxmox-vm/blob/main/provider.tf),
not a range. The provider's 3.x line is still shipping release candidates, and
two of them have changed resource behaviour without a major-version bump. A
range would let that reach consumers unannounced.

| | |
|---|---|
| **Current pin** | `3.0.2-rc09` |
| **Previous pin** | `3.0.2-rc07` |
| **Skipped** | `3.0.2-rc08` — see [below](#why-rc08-is-skipped) |

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
