#!/bin/bash
# Proxmox VM snapshot helper.
# Operates on whichever QEMU VM is currently selected in a logged-in Proxmox Chrome tab.
#
# Usage:
#   pve.sh setup [PVE_HOST]                             # write config; if no arg, opens $EDITOR
#   pve.sh whoami
#   pve.sh list-vms                                     # list all VMs in cluster
#   pve.sh list
#   pve.sh create <snapname> [description] [vmstate]   # vmstate=1 keeps RAM (default 1)
#   pve.sh rollback <snapname>
#   pve.sh delete <snapname>
#   pve.sh refresh        # drop cred cache
#   pve.sh clear-cache    # drop all caches
#
# Auth:
#   PVEAuthCookie + CSRFPreventionToken are extracted once from the open
#   Proxmox tab (osascript + injected <script>) and cached for ~90 minutes.
#   All API calls are plain curl. On 401 the creds are re-extracted once.
#
# Target VM:
#   Determined dynamically from the URL fragment of the open Proxmox tab
#   (matches "=qemu%2F<vmid>"). vmid is then resolved via cluster/resources
#   to its node and name. Switch tab in Chrome to switch target VM.

set -euo pipefail

CONFIG_FILE="${HOME}/.config/tl-util-proxmox-snap.conf"
CACHE_DIR="${TMPDIR:-/tmp}/tl-util-proxmox-snap"
CRED_FILE="${CACHE_DIR}/creds"
CRED_TTL=5400      # 90 min
VM_TTL=86400       # 24 h

mkdir -p "$CACHE_DIR"
chmod 700 "$CACHE_DIR"

# ----- config -----

load_config() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: $CONFIG_FILE not found. Run: $0 setup" >&2
    return 1
  fi
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
  if [[ -z "${PVE_HOST:-}" ]]; then
    echo "ERROR: PVE_HOST not set in $CONFIG_FILE" >&2
    return 1
  fi
  PVE_HOST_MATCH="${PVE_HOST#https://}"
  PVE_HOST_MATCH="${PVE_HOST_MATCH#http://}"
  PVE_HOST_MATCH="${PVE_HOST_MATCH%/}"
}

# ----- osascript bridge -----

# Inject a JS body (passed base64) into the Proxmox tab; capture document.title result.
run_in_tab() {
  local body="$1"
  local b64
  b64=$(printf '%s' "$body" | base64 | tr -d '\n')
  SCRIPT_B64="$b64" HOST_MATCH="$PVE_HOST_MATCH" osascript <<'APPLESCRIPT' 2>&1
set scriptB64 to system attribute "SCRIPT_B64"
set hostMatch to system attribute "HOST_MATCH"
tell application "Google Chrome"
  set theTab to missing value
  repeat with w in windows
    repeat with t in tabs of w
      if (URL of t) contains hostMatch then
        set theTab to t
        exit repeat
      end if
    end repeat
    if theTab is not missing value then exit repeat
  end repeat
  if theTab is missing value then return "ERROR: no Proxmox tab found (open " & hostMatch & " and log in)"
  set js to "(function(){try{var __o=document.title;var s=document.createElement('script');s.textContent=atob('" & scriptB64 & "');document.documentElement.appendChild(s);s.remove();var r=document.title;document.title=__o;return r;}catch(e){return 'ERR:'+e.message;}})()"
  execute theTab javascript js
end tell
APPLESCRIPT
}

# Extract URL + cookie + token in a single osascript call.
# Output sets document.title = "TAB:<url>|<cookie>|<token>"
extract_tab_state() {
  local body
  body="var u=location.href;var c=document.cookie.split(';').map(function(s){return s.trim()}).find(function(s){return s.indexOf('PVEAuthCookie=')===0});var t=(window.Proxmox&&Proxmox.CSRFPreventionToken)||'';document.title='TAB:'+u+'|'+(c?c.substr(14):'')+'|'+t;"
  local out
  out=$(run_in_tab "$body")
  if [[ "$out" != TAB:* ]]; then
    echo "$out" >&2
    return 1
  fi
  echo "${out#TAB:}"
}

# ----- credentials -----

ensure_creds() {
  if [[ -f "$CRED_FILE" ]]; then
    local age
    age=$(( $(date +%s) - $(stat -f %m "$CRED_FILE" 2>/dev/null || stat -c %Y "$CRED_FILE") ))
    if (( age < CRED_TTL )); then
      # shellcheck disable=SC1090
      source "$CRED_FILE"
      [[ -n "${COOKIE:-}" && -n "${TOKEN:-}" ]] && return 0
    fi
  fi
  # need fresh state; also gives us URL for vmid detection
  local state cookie token url
  state=$(extract_tab_state) || return 1
  url="${state%%|*}"; state="${state#*|}"
  cookie="${state%%|*}"; token="${state#*|}"
  if [[ -z "$cookie" || -z "$token" ]]; then
    echo "ERROR: empty cookie or token (session expired? log in to Proxmox again)" >&2
    return 1
  fi
  COOKIE="$cookie"; TOKEN="$token"; LAST_URL="$url"
  umask 077
  printf 'COOKIE=%s\nTOKEN=%s\n' "$COOKIE" "$TOKEN" > "$CRED_FILE"
}

# ----- VM detection -----

# Sets VMID by reading the tab URL; uses LAST_URL if extract_tab_state already ran.
detect_vmid() {
  local url="${LAST_URL:-}"
  if [[ -z "$url" ]]; then
    local state
    state=$(extract_tab_state) || return 1
    url="${state%%|*}"
  fi
  if [[ "$url" =~ =qemu%2F([0-9]+) ]]; then
    VMID="${BASH_REMATCH[1]}"
  else
    echo "ERROR: open Proxmox tab does not point to a QEMU VM (URL: $url)" >&2
    echo "       click into a VM in the Proxmox UI, then retry." >&2
    return 1
  fi
}

# Resolve VMID -> NODE + VMNAME + STATUS via cluster/resources, with cache.
resolve_vm() {
  local cache="${CACHE_DIR}/vm-${VMID}.cache"
  if [[ -f "$cache" ]]; then
    local age
    age=$(( $(date +%s) - $(stat -f %m "$cache" 2>/dev/null || stat -c %Y "$cache") ))
    if (( age < VM_TTL )); then
      # shellcheck disable=SC1090
      source "$cache"
      return 0
    fi
  fi
  ensure_creds
  local resp
  resp=$(curl -sk \
    -b "PVEAuthCookie=${COOKIE}" \
    "${PVE_HOST}/api2/json/cluster/resources?type=vm")
  local row
  row=$(echo "$resp" | jq --argjson id "$VMID" -r '.data[] | select(.vmid==$id)')
  if [[ -z "$row" ]]; then
    echo "ERROR: vmid ${VMID} not found in cluster/resources" >&2
    return 1
  fi
  NODE=$(echo "$row" | jq -r '.node')
  VMNAME=$(echo "$row" | jq -r '.name')
  STATUS=$(echo "$row" | jq -r '.status')
  printf 'NODE=%s\nVMNAME=%s\nSTATUS=%s\n' "$NODE" "$VMNAME" "$STATUS" > "$cache"
}

# ----- API call -----

api() {
  local method="$1" path="$2"; shift 2
  ensure_creds
  local code resp tmp="${CACHE_DIR}/resp.$$"
  code=$(curl -sk -o "$tmp" -w '%{http_code}' \
    -X "$method" \
    -b "PVEAuthCookie=${COOKIE}" \
    -H "CSRFPreventionToken: ${TOKEN}" \
    "$@" \
    "${PVE_HOST}${path}")
  resp=$(cat "$tmp"); rm -f "$tmp"
  if [[ "$code" == "401" ]]; then
    rm -f "$CRED_FILE"
    ensure_creds
    code=$(curl -sk -o "$tmp" -w '%{http_code}' \
      -X "$method" \
      -b "PVEAuthCookie=${COOKIE}" \
      -H "CSRFPreventionToken: ${TOKEN}" \
      "$@" \
      "${PVE_HOST}${path}")
    resp=$(cat "$tmp"); rm -f "$tmp"
  fi
  echo "${code}|${resp}"
}

# ----- subcommands -----

cmd_setup() {
  mkdir -p "$(dirname "$CONFIG_FILE")"
  local host="${1:-}"
  if [[ -n "$host" ]]; then
    cat > "$CONFIG_FILE" <<EOF
# tl-util-proxmox-snap config
PVE_HOST=${host}
EOF
    chmod 600 "$CONFIG_FILE"
    echo "wrote $CONFIG_FILE (PVE_HOST=${host})"
    echo "next: $0 whoami"
    return
  fi
  if [[ ! -f "$CONFIG_FILE" ]]; then
    cat > "$CONFIG_FILE" <<'EOF'
# tl-util-proxmox-snap config
# Set PVE_HOST to your Proxmox base URL, e.g.
#   PVE_HOST=https://10.x.x.x:8006
PVE_HOST=
EOF
    chmod 600 "$CONFIG_FILE"
    echo "created $CONFIG_FILE"
  else
    echo "$CONFIG_FILE already exists"
  fi
  echo "edit it to set PVE_HOST, then run: $0 whoami"
  if [[ -n "${EDITOR:-}" ]]; then
    "$EDITOR" "$CONFIG_FILE"
  fi
}

cmd_whoami() {
  load_config
  ensure_creds
  detect_vmid
  resolve_vm
  echo "vmid=${VMID} name=${VMNAME} node=${NODE} status=${STATUS}"
}

cmd_list_vms() {
  load_config
  ensure_creds
  local resp
  resp=$(curl -sk \
    -b "PVEAuthCookie=${COOKIE}" \
    "${PVE_HOST}/api2/json/cluster/resources?type=vm")
  echo "$resp" | jq -r '.data | sort_by(.vmid) | .[] | [.vmid, .name, .node, .status] | @tsv'
}

snap_base() {
  load_config
  ensure_creds
  detect_vmid
  resolve_vm
  BASE="/api2/json/nodes/${NODE}/qemu/${VMID}/snapshot"
}

cmd="${1:-}"; shift || true
case "$cmd" in
  setup)        cmd_setup "${1:-}" ;;
  whoami)       cmd_whoami ;;
  list-vms)     cmd_list_vms ;;
  list)         snap_base; api GET "${BASE}" ;;
  create)
    snap_base
    name="${1:?snapname required}"; desc="${2:-}"; vmstate="${3:-1}"
    safe_name=$(printf '%s' "$name" | sed 's/[^A-Za-z0-9_]/_/g')
    if [[ -n "$desc" ]]; then
      api POST "${BASE}" \
        --data-urlencode "snapname=${safe_name}" \
        --data-urlencode "vmstate=${vmstate}" \
        --data-urlencode "description=${desc}"
    else
      api POST "${BASE}" \
        --data-urlencode "snapname=${safe_name}" \
        --data-urlencode "vmstate=${vmstate}"
    fi
    ;;
  rollback)
    snap_base
    name="${1:?snapname required}"
    api POST "${BASE}/${name}/rollback"
    ;;
  delete)
    snap_base
    name="${1:?snapname required}"
    api DELETE "${BASE}/${name}"
    ;;
  refresh)      rm -f "$CRED_FILE"; echo "ok" ;;
  clear-cache)  rm -rf "$CACHE_DIR"; echo "ok" ;;
  *)
    echo "usage: $0 {setup|whoami|list-vms|list|create <name> [desc] [vmstate]|rollback <name>|delete <name>|refresh|clear-cache}" >&2
    exit 1
    ;;
esac
