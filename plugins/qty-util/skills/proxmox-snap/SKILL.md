---
name: proxmox-snap
description: Manage Proxmox VM snapshots (list/create/rollback/delete) on whichever QEMU VM is currently selected in a logged-in Proxmox Chrome tab on macOS. Trigger when user mentions Proxmox snapshot, VM snapshot, rollback a VM, or asks to create/list/delete Proxmox snapshots.
---

# tl-util-proxmox-snap

## Target selection

The skill operates on whichever VM the user is currently looking at in their Proxmox web UI. The Chrome tab's URL fragment encodes the selected VM (`=qemu%2F<vmid>`); the script reads that and resolves vmid → node + name via `cluster/resources`.

To switch target VM, the user clicks a different VM in Proxmox UI — no config change.

## Prerequisite

1. A Chrome tab opened on the configured Proxmox host and logged in.
2. That tab is currently selected on a QEMU VM (not on a node, container, or dashboard).

## First-time setup

Ask the user for the Proxmox host URL (e.g. `https://10.x.x.x:8006`), then run `scripts/pve.sh setup <PVE_HOST>` to write `~/.config/tl-util-proxmox-snap.conf`. If invoked without an argument, the script falls back to creating an empty config and opening it in `$EDITOR`.

After setup, run `pve.sh whoami` to verify everything works end-to-end.

The skill also requires two macOS permissions before Chrome cookie extraction works:
1. System Settings → Privacy & Security → Automation: grant your terminal app (Terminal/iTerm/Ghostty) permission to control Google Chrome.
2. Chrome → View → Developer → Allow JavaScript from Apple Events.

## Auth and caching

- Cookie + CSRF token extracted once from the Chrome tab via osascript, cached in `$TMPDIR/tl-util-proxmox-snap/creds` (mode 600, TTL 90 min).
- vmid → node/name mapping cached per-vm in the same dir, TTL 24h.
- All API calls are plain curl; on 401 the creds are auto-refreshed once.
- `pve.sh refresh` to drop cred cache. `pve.sh clear-cache` for everything.

## Subcommands

```
pve.sh setup [PVE_HOST]                                # write config; if no arg, opens $EDITOR
pve.sh whoami                                          # show current target
pve.sh list-vms                                        # list all VMs in cluster (vmid, name, node, status)
pve.sh list
pve.sh create <snapname> [description] [vmstate]      # vmstate=1 keeps RAM (default 1)
pve.sh rollback <snapname>
pve.sh delete <snapname>
pve.sh refresh
pve.sh clear-cache
```

Output format for API calls: `<http_status>|<json_body>`. Use `jq` to parse.

The `current` entry returned by `list` is a virtual node ("You are here!"), not a real snapshot. Filter it out when presenting choices.

## Workflows

Always run `pve.sh whoami` at the start and show the user `name (vmid=N, node=X, status=...)`. If wrong VM, ask them to switch tab in Chrome and re-run.

### list

`pve.sh list`, parse with jq, show snapshots as a table (name, snaptime as local time, vmstate, description). Skip the `current` entry.

### create — always go through this flow

1. Run `pve.sh whoami` and show target VM.
2. Run `pve.sh list` and show existing snapshots.
3. Ask the user for the intent / purpose of this snapshot (one short phrase). RAM is always included (`vmstate=1`) — do not ask.
4. Convert the intent to a legal Proxmox snapshot id:
   - regex must match: `^[A-Za-z][A-Za-z0-9_]{2,39}$`
   - format: `YYYYMMDD_<slug>` where slug is the intent lowercased, non-alphanum → `_`, collapsed
   - if it would start with a digit, prefix with `s` (e.g. `s20260413_xxx`)
   - keep total length ≤ 40
   - example: intent "before kernel upgrade" on 2026-04-13 → `s20260413_before_kernel_upgrade`
5. Show final id + description, get a yes, then run `pve.sh create <id> "<intent>"` (vmstate defaults to 1).
6. Verify with `pve.sh list`.

### rollback

1. `pve.sh whoami` → confirm target VM.
2. `pve.sh list` → ask which snapshot.
3. Confirm explicitly — rollback discards anything since that snapshot.
4. `pve.sh rollback <name>`. Returns a UPID; operation is async on Proxmox side.
5. Re-run `pve.sh list` to confirm `current.parent` now points to the chosen snapshot.

### delete

1. `pve.sh whoami` → confirm target VM.
2. `pve.sh list` → ask which snapshot to delete.
3. Confirm explicitly.
4. `pve.sh delete <name>`.

## Error handling

- `ERROR: no Proxmox tab found` → ask user to open and log into Proxmox in Chrome.
- `ERROR: open Proxmox tab does not point to a QEMU VM` → ask user to click into a VM in the Proxmox UI.
- `ERROR: empty cookie or token` → session expired, re-login in Chrome, then `pve.sh refresh`.
- HTTP 404 on `cluster/resources` row → vmid in URL doesn't exist in this cluster.
