# LabUL: `ul-pve11` kann nicht klonen (Storage-API hängt)

**Festgestellt:** 2026-08-24 · **Status:** offen, nicht angefasst · **Betrifft:** nur `ul-pve11`

Kurzfassung für den Admin. Der Node ist online und die VMs darauf laufen, aber
**jeder Storage-bezogene API-Call läuft in den 30-Sekunden-Timeout**. Damit
schlägt auf diesem Node jeder Clone fehl, weil ein Clone den Ziel-Storage
auflösen muss.

## Symptom

```
Error: 596 Connection timed out
```

Mehr nicht — der Fehler nennt weder den Node noch den Storage. Er tritt
identisch bei Terraform, beim rohen `curl` gegen die API und im Crossplane-Pfad
auf, ist also **kein Client-Problem**.

## Messung

Gleicher Ticket, gleicher Zeitpunkt, nur der Node unterscheidet sich:

```
/nodes/ul-pve01/storage  -> 200  0.31s
/nodes/ul-pve02/storage  -> 200  0.29s
/nodes/ul-pve10/storage  -> 200  0.30s
/nodes/ul-pve11/storage  -> 596 30.04s     <-- exakt der Proxy-Timeout
```

Auf `ul-pve11` selbst ist die Trennlinie sehr scharf:

| Endpoint | Ergebnis |
|---|---|
| `/nodes/ul-pve11/status` | 200 in 0,047 s |
| `/nodes/ul-pve11/network` | 200 in 0,068 s |
| `/nodes/ul-pve11/tasks` | 200 in 0,046 s |
| `/nodes/ul-pve11/subscription` | 200 in 0,044 s |
| `/nodes/ul-pve11/qemu/211/config` | 200 (liest nur pmxcfs) |
| **`/nodes/ul-pve11/qemu`** | **596 nach 30,0 s** |
| **`/nodes/ul-pve11/storage`** | **596 nach 30,0 s** |
| **`/nodes/ul-pve11/storage/local/status`** | **596 nach 30,0 s** |

## Was das nahelegt

Alles, was **kein** Dateisystem anfassen muss, antwortet in Millisekunden.
Alles, was über die Mounts iteriert, hängt exakt 30 Sekunden.

Entscheidend: **auch `local` hängt.** Das ist ein simpler Directory-Store auf
der lokalen Platte des Nodes. Es ist also nicht ein einzelner kaputter
Remote-Storage, sondern der Storage-Layer als Ganzes — typisch für einen
**hängenden NFS-Mount**, der Prozesse in den D-State schickt, sodass jeder
`statfs`-Durchlauf über alle Mounts blockiert. `/nodes/<n>/qemu` ist mit
betroffen, weil die VM-Liste die Disk-Belegung pro VM ermittelt.

Kandidaten auf dem Node: `DD-sthings` (NFS) und `Import-53` (ESXi-Import-Storage,
meldet clusterweit `free=0G`).

## Erste Schritte auf dem Node

```bash
# hängende Mounts / D-State-Prozesse
ps -eo state,pid,comm | awk '$1=="D"'
cat /proc/*/stack 2>/dev/null | head

# welcher Mount blockiert
timeout 5 stat -f /mnt/pve/DD-sthings || echo "DD-sthings haengt"
timeout 5 stat -f /var/lib/vz          || echo "local haengt"
mount | grep -E 'nfs|esxi'

systemctl status pvestatd pvedaemon
journalctl -u pvestatd -u pvedaemon --since '-2h' | grep -iE 'timeout|nfs|stale|storage'
```

Erfahrungsgemäß reicht danach oft ein `systemctl restart pvestatd` — aber nur,
wenn der blockierende Mount vorher weg ist, sonst hängt der Neustart genauso.

## Auswirkung

**Laufende VMs sind nicht betroffen** — sie laufen weiter, u. a.
`argoplatform-test2` (253) und `homerun2-test1` (254). Betroffen ist die
Verwaltung: keine Clones, keine neuen VMs, und Crossplane kann VMs auf diesem
Node nicht mehr abgleichen.

**Blockiert konkret:**

- Alle drei ubuntu26-Templates liegen auf `ul-pve11` — VMID **144**, **192**,
  **211**. Die sind damit aktuell nicht klonbar.
- Die `labul`-EnvironmentConfig in `crossplane-configurations`
  (`machinery/proxmoxvm`) pinnt `node: ul-pve11` und `templateVmId: 211`. Der
  gesamte `NativeProxmoxVM`-Pfad läuft also derzeit in denselben 596.
- Übrig bleibt Template **110** (`sthings-u26`) auf `ul-pve10`. Damit lässt
  sich bauen (verifiziert), aber 110 bringt `/etc/cloud/cloud-init.disabled`
  mit, wertet Cloud-Init im Gast also nicht aus.

## Gegenprobe für danach

```bash
curl -sk -o /dev/null -w '%{http_code} %{time_total}s\n' --max-time 45 \
  -b "PVEAuthCookie=$PVE_TICKET" "$PVE_HOST/api2/json/nodes/ul-pve11/storage"
# erwartet: 200 und < 1s
```
