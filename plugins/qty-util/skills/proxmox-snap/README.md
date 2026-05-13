# proxmox-snap

Manage Proxmox VM snapshots (list / create / rollback / delete) on whichever QEMU VM is currently selected in your Proxmox web UI Chrome tab.

The skill reads the Chrome tab's URL to know which VM you mean — switch tab, switch target. No flags, no vmid memorization.

## Prerequisites

Platform: macOS only (uses `osascript` to read Chrome tabs).

System tools: `bash`, `curl`, `jq`.

Runtime requirements:

1. Google Chrome opened on your Proxmox web UI, logged in, and clicked into a QEMU VM (URL contains `=qemu%2F<vmid>`).
2. macOS automation permission — System Settings → Privacy & Security → Automation: grant your terminal app (Terminal / iTerm / Ghostty) permission to control Google Chrome.
3. Chrome → View → Developer → Allow JavaScript from Apple Events. (Without this the cookie/token extraction returns empty.)

## First-time setup

```bash
scripts/pve.sh setup https://your-proxmox-host:8006
scripts/pve.sh whoami
```

`whoami` should print `vmid=N name=... node=... status=...`. If you get `ERROR: empty cookie or token`, recheck the two permissions above and re-login Chrome.

## Daily use

```bash
scripts/pve.sh list-vms                 # list every VM in the cluster
scripts/pve.sh whoami                   # show the VM you're currently pointing at
scripts/pve.sh list                     # list snapshots of the current VM
scripts/pve.sh create <name> [desc]     # create snapshot (RAM included by default)
scripts/pve.sh rollback <name>          # rollback to snapshot — discards anything since
scripts/pve.sh delete <name>            # delete snapshot
scripts/pve.sh refresh                  # drop cached cookie (after re-login)
scripts/pve.sh clear-cache              # drop all caches
```

API output format is `<http_status>|<json_body>` — pipe through `jq` to parse.

## Using with Claude Code

Drop this skill into your project's `.claude/skills/` directory (or wherever your Claude Code setup loads skills from). Trigger it by mentioning `proxmox-snap` in conversation; Claude will guide you through setup, list/create/rollback/delete flows, and snapshot naming conventions.

## Caching

- Cookie + CSRF token cached in `$TMPDIR/tl-util-proxmox-snap/creds` (mode 600, TTL 90 min).
- vmid → node/name mapping cached per-VM in the same dir (TTL 24h).
- On HTTP 401, credentials are auto-refreshed once.
