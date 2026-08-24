# Migration: `disk` → `disks`

This module moved from Telmate's legacy `disk` block to its `disks` block.
This page is the whole story: why, what changes for you, and what the plan
should look like.

## TL;DR

| | |
|---|---|
| **Does it destroy my VM?** | **No.** There is no `ForceNew` anywhere in the provider's disk package — the switch is an in-place update. |
| **Do I have to change my config?** | Only if you set `vm_bootdisk` to something outside slots 0/1 of a bus, or if you want cloud-init. |
| **What do I gain?** | Cloud-init actually works, plus per-disk `format`, `cache`, `iothread`, `discard`, `emulatessd`, `backup`, `replicate`. |
| **What must I check first?** | Whether the VM carries a disk this module does not declare. See [The one real hazard](#the-one-real-hazard). |

## Why

The two blocks are mutually exclusive at the schema level:

```
Error: Conflicting configuration arguments
  "disk": conflicts with disks
```

and **only `disks` can configure a cloud-init drive** — it is reachable solely
as `disks { ide { ide2 { cloudinit { storage } } } }`. While the module used
`disk`, every `vm_ci_*` variable was accepted and silently ignored, because
Proxmox had nowhere to write the generated user-data.

It was worse than merely missing, though.

## The bug this fixes

Both blocks build their API request the same way: start with **every slot
marked for deletion**, then fill in what the config declares.

```go
// proxmox/Internal/resource/guest/qemu/disk/sdk_disks.go
func sdk_Disks_QemuIdeDisksDefault() *pveAPI.QemuIdeDisks {
	return &pveAPI.QemuIdeDisks{
		Disk_0: &pveAPI.QemuIdeStorage{Delete: true},
		Disk_1: &pveAPI.QemuIdeStorage{Delete: true},
		Disk_2: &pveAPI.QemuIdeStorage{Delete: true},
		Disk_3: &pveAPI.QemuIdeStorage{Delete: true}}
}
```

And `Delete` is honoured like this:

```go
// proxmox-api-go: proxmox/config__qemu__disk.go
func (storage qemuStorage) mapToApiValues(currentStorage *qemuStorage, …, delete string) string {
	if storage.delete {
		if currentStorage == nil {
			return delete                        // empty slot: no-op
		}
		return delete + "," + id.String()        // occupied slot: REMOVED
	}
```

So a template that shipped a cidata drive on `ide2` had it **deleted on the
first apply**, because the old config declared only `virtio0`. That is the real
reason cloud-init "did not work" with this module — not a missing field, a
removed drive.

## What changed in the module

**Before**

```hcl
disk {
  size    = var.vm_disk_size
  slot    = var.vm_bootdisk
  storage = var.pve_datastore
}
```

**After** — the boot slot routed into the right nested block, plus an optional
cidata drive:

```hcl
disks {
  virtio {
    virtio0 {
      disk {
        size    = var.vm_disk_size
        storage = var.pve_datastore
        # … format / cache / iothread / discard / backup / replicate
      }
    }
  }
  ide {
    ide2 {
      cloudinit {
        storage = var.vm_cloudinit_datastore
      }
    }
  }
}
```

Terraform cannot compute a block name, so each supported slot needs its own
`dynamic` block gated on a local. That is why `vm.tf` now carries a generated
section, and why `vm_bootdisk` is validated against a fixed list.

## Behaviour changes

### 1. `vm_bootdisk` is validated

It selects a nested block now, so it is no longer free-form. Accepted:
`virtio0`, `virtio1`, `scsi0`, `scsi1`, `sata0`, `sata1`, `ide0`, `ide1`.

Anything else fails at plan time with a clear message. To add a slot, extend
both the validation in `variables.tf` and the generated block list in `vm.tf`.

### 2. Cloud-init needs a datastore

Set `vm_cloudinit_datastore` to emit the drive. A `check` block warns if you
set any `vm_ci_*` without it.

**Pick a datastore that survives a stop/start.** The cidata image is the one
disk Proxmox frees and re-allocates on every power cycle. On LabUL's
`V5010-01-1` that round trip is broken: the stop leaves an LV behind that no
device node backs, and the next start dies on `lvcreate … already exists` with
the VM unbootable until the volume is deleted through the API. Point it at a
filesystem-backed store — LabUL uses the NFS store `DD-sthings`.

### 3. Per-bus attribute limits are enforced

Telmate exposes different attributes per bus. Preconditions now reject the
combinations that would otherwise fail obscurely:

| Attribute | Available on |
|-----------|--------------|
| `iothread` | scsi, virtio |
| `emulatessd` | ide, sata, scsi |
| everything else | all buses |

## The one real hazard

**The `disks` block is authoritative: any slot it does not declare is deleted
if it is occupied.**

This is *not new* — the legacy block had identical semantics — but the
migration is the right moment to check. You are affected if the VM carries a
disk this module does not manage:

- a second data disk added by hand in the Proxmox UI
- a cidata drive from the template that somehow survived
- an ISO/CD-ROM left attached

Check before applying:

```bash
qm config <vmid> | grep -E '^(virtio|scsi|sata|ide)[0-9]+:'
```

If anything other than your boot slot shows up, either declare it (extend the
generated block list) or detach it in Proxmox first. **The module manages
exactly one data disk plus an optional cidata drive.**

## Running the migration

```bash
terraform init -upgrade
terraform plan          # READ IT. See below for what is expected.
terraform apply
terraform plan          # must now report: No changes.
```

### What a healthy plan looks like

An **in-place update** (`~`), not a replacement (`-/+`). The `disk` attribute
empties and `disks` fills:

```
~ resource "proxmox_vm_qemu" "proxmox_vm" {
    - disk {
    -     size    = "100G" -> null
    -     slot    = "virtio0" -> null
    -     storage = "V5010-01-1" -> null
      }
    + disks {
    +     virtio {
    +         virtio0 {
    +             disk {
    +                 size    = "100G"
    +                 storage = "V5010-01-1"
```

Because the real VM already has `virtio0` at that size and storage, the API
call is a no-op for the disk itself; the state representation is what
converges.

**If you see `-/+ destroy and then create replacement`, stop.** That is not
this migration — something else in the config changed (`vm_clone_id`,
`vm_full_clone`, `vm_smbios_*`, `vm_id`, or `nodeName`). Find it before
applying.

### Rollback

Pin the previous module version. Nothing in Proxmox changed, so reverting the
`source` ref and re-applying puts the state representation back.

## Crossplane / provider-terraform

Same migration, but the apply is unattended. Two extra precautions:

1. Run `terraform plan` **locally first** against a copy of the Workspace's
   variables, so a surprise is not discovered by a reconcile loop.
2. Consider pausing reconciliation while you roll it out:
   `kubectl annotate workspace <name> crossplane.io/paused=true`

`vm_cloudinit_datastore` is a plain string, so it goes in
`spec.forProvider.vars` like any other scalar.

## Verifying it worked

```bash
qm config <vmid> | grep -E 'ide2|virtio0'
#   virtio0: V5010-01-1:vm-9144-disk-0,size=100G
#   ide2: DD-sthings:vm-9144-cloudinit,media=cdrom

ssh sthings@<ip> 'cloud-init status && hostname'
ssh sthings@<ip> 'sudo passwd -S sthings'   # must NOT report L
```
