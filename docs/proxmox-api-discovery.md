# Proxmox API Discovery

Before using this module, you need to know which Proxmox resources are available (nodes, templates, datastores, networks, pools). The Proxmox REST API can be queried directly with `curl` to gather this information.

## Authentication

Authenticate against the Proxmox API to get a session ticket:

```bash
export PVE_HOST="https://your-pve-host:8006"
export PVE_TICKET=$(curl -sk \
  -d "username=user@realm&password=secret" \
  "$PVE_HOST/api2/json/access/ticket" | jq -r '.data.ticket')
```

## Cluster Nodes

List all nodes in the cluster (`pve_cluster_node`):

```bash
curl -sk -b "PVEAuthCookie=$PVE_TICKET" \
  "$PVE_HOST/api2/json/nodes" | jq -r '.data[] | "\(.node) (\(.status))"'
```

## VM Templates

List available templates to clone from (`vm_template`):

```bash
curl -sk -b "PVEAuthCookie=$PVE_TICKET" \
  "$PVE_HOST/api2/json/cluster/resources?type=vm" \
  | jq '.data[] | select(.template==1) | {name, vmid, node}'
```

## Datastores

List storage backends (`pve_datastore`):

```bash
curl -sk -b "PVEAuthCookie=$PVE_TICKET" \
  "$PVE_HOST/api2/json/storage" \
  | jq -r '.data[] | "\(.storage) (\(.type)) - \(.content)"'
```

To see usage per node:

```bash
curl -sk -b "PVEAuthCookie=$PVE_TICKET" \
  "$PVE_HOST/api2/json/nodes/<node>/storage" \
  | jq '.data[] | {storage, type, avail, total, used_fraction}'
```

## Network Bridges

List available bridges per node (`pve_network`):

```bash
curl -sk -b "PVEAuthCookie=$PVE_TICKET" \
  "$PVE_HOST/api2/json/nodes/<node>/network" \
  | jq -r '.data[] | select(.type=="bridge") | .iface'
```

## Resource Pools

List pools (`pve_folder_path`):

```bash
curl -sk -b "PVEAuthCookie=$PVE_TICKET" \
  "$PVE_HOST/api2/json/pools" | jq -r '.data[].poolid'
```

## Example Output

Real output from LabUL, **2026-08-24**. Treat it as a snapshot, not a
reference — every value below had already drifted from the documents that
described it. The whole point of this page is that you re-run the queries
instead of copying values out of a doc.

```
=== NODES ===
ul-pve01 (online)
ul-pve02 (online)
ul-pve10 (online)
ul-pve11 (online)      <- storage API hangs, cannot clone; see below

=== TEMPLATES ===
sthings-u26                 (vmid: 110, node: ul-pve10)
ubuntu26-base-os            (vmid: 144, node: ul-pve11)
ubuntu26-base-20260728-1419 (vmid: 192, node: ul-pve11)
ubuntu26-base-20260731-0909 (vmid: 211, node: ul-pve11)
Deb13-Template              (vmid: 996, node: ul-pve10)

=== STORAGE ===
V5010-01-1 (lvm) - images,rootdir
DD-sthings (nfs) - vztmpl,import,rootdir,snippets,iso,images,backup
local-lvm  (lvmthin) - rootdir,images

=== BRIDGES ===
vmbr0
vmbrvlan

=== POOLS ===
stuttgart-things
LabUL-Infra
```

## Mapping to Module Variables

| API Query | Module Variable |
|-----------|----------------|
| Nodes | `pve_cluster_node` |
| Templates | `vm_template` |
| Storage | `pve_datastore` |
| Bridges | `pve_network` |
| Pools | `pve_folder_path` |


## Two things the queries above will not tell you

**1. A node can be "online" and still be unable to build.** `ul-pve11` reports
`online` in `/cluster/status` and answers `/nodes/ul-pve11/status` in
milliseconds, but every *storage* call on it times out:

```bash
for n in ul-pve01 ul-pve02 ul-pve10 ul-pve11; do
  echo -n "$n -> "
  curl -sk -o /dev/null -w '%{http_code} %{time_total}s\n' --max-time 45 \
    -b "PVEAuthCookie=$PVE_TICKET" "$PVE_HOST/api2/json/nodes/$n/storage"
done
# ul-pve01 -> 200 0.3s
# ul-pve11 -> 596 30.0s
```

A clone has to resolve the target storage, so on such a node it fails with a
bare `596 Connection timed out` that names neither the node nor the storage.
**Run this check before blaming Terraform or the provider.**

**2. Whether a template has a cloud-init drive.** The template listing does not
show it, and no LabUL template has one — they are all `virtio0` and nothing
else. Check per template:

```bash
curl -sk -b "PVEAuthCookie=$PVE_TICKET" \
  "$PVE_HOST/api2/json/nodes/<node>/qemu/<vmid>/config" \
  | jq '{name, virtio0, scsi0, ide2}'
```

No `ide2` means every `vm_ci_*` variable is inert unless you set
`vm_cloudinit_datastore`, which makes this module create the drive.
