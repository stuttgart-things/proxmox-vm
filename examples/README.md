# Examples

Each directory is a standalone root module. Run one with:

```bash
cd examples/01-minimal
terraform init
terraform plan -var-file=../../my.tfvars   # or export TF_VAR_pve_api_password=…
```

| # | Example | What it shows |
|---|---------|---------------|
| 01 | [`01-minimal`](01-minimal/) | Smallest working call. Clone by name, DHCP, every opt-in feature off. |
| 02 | [`02-cloud-init`](02-cloud-init/) | **The recommended path.** Static IP, user, password, SSH keys, DNS — no post-create SSH dependency. |
| 03 | [`03-clone-by-vmid`](03-clone-by-vmid/) | Clone by template VMID, pinned VMID, VLAN tag, tags, a 100G disk. |
| 04 | [`04-uefi-secureboot`](04-uefi-secureboot/) | OVMF firmware plus the EFI vars disk it needs to be usable. |
| 05 | [`05-multi-vm`](05-multi-vm/) | `vm_count` fan-out, the asymmetric naming rule, and what it costs you. |
| 06 | [`06-labul-kind`](06-labul-kind/) | A field-by-field port of the Crossplane `NativeProxmoxVM` XR, with the three things that do **not** map spelled out. |
| 07 | [`07-legacy-ssh-bootstrap`](07-legacy-ssh-bootstrap/) | Restoring the old unconditional SSH bootstrap, and why you probably shouldn't. |
| 08 | [`08-crossplane-workspace`](08-crossplane-workspace/) | Driving the module from a `provider-terraform` Workspace, including the string-only `vars` trap. |
| 09 | [`09-labul-smoketest`](09-labul-smoketest/) | **The config that actually built a VM** (LabUL, 2026-08-24, verified and torn down). Starting point for the Dagger build. |

## Reading order

If you are new to the module: **01 → 02**. That covers most real use.

If you are porting from the Crossplane `NativeProxmoxVM` XR: go straight to
**06**, which is annotated against that XR field by field.

If you are wondering why your VM ignores its cloud-init settings: **02**, first
paragraph — you need `vm_cloudinit_datastore`.

If you want values that are known to work rather than placeholders: **09**. The
generic examples use invented template names like `ubuntu22`; 09 uses what is
really on the cluster.

## Credentials

None of the examples hard-code API credentials. Supply them however you
normally would:

```bash
export TF_VAR_pve_api_url="https://pve.example.com:8006/api2/json"
export TF_VAR_pve_api_user="terraform@pve"
export TF_VAR_pve_api_password="…"
```

Mind that `pve_api_tls_verify` is inverted — `true` (the default) *disables*
certificate checking. See the variable's description.
