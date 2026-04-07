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

```
=== NODES ===
ul-pve01 (online)
ul-pve02 (online)

=== TEMPLATES ===
ubuntu24 (vmid: 160, node: ul-pve01)
ubuntu22 (vmid: 152, node: ul-pve01)
rocky9   (vmid: 140, node: ul-pve01)

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
