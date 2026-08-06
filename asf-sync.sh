#!/usr/bin/env bash
# =============================================================================
# Project Pulse — ASF Mailing List Sync
# =============================================================================
#
# Fetches structured JSON from lists.apache.org API (PonyMail) and caches it
# locally. ASF lists do not use git/mbox — they expose a REST-ish JSON API.
#
# Usage:
#   asf-sync.sh --status           Show cached data for each registered list
#   asf-sync.sh --sync             Fetch (or re-fetch) current month for all active lists
#   asf-sync.sh --sync <name>      Fetch for one specific list only
#   asf-sync.sh --init-caches      Pre-warm caches for all active lists
#
# Data source:
#   https://lists.apache.org/api/stats.lua?list=<list>&domain=<domain>&d=YYYY-M
#
# Cache layout:
#   data/asf/<name>-<YYYY-MM>.json    — full stats.lua response
#   data/asf/<name>-<YYYY-MM>.meta    — timestamp + hash metadata
#
# Registry: asf-registry.yaml
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGISTRY="${SCRIPT_DIR}/asf-registry.yaml"
DATA_DIR="${SCRIPT_DIR}/data/asf"
API_BASE="https://lists.apache.org/api"
TIMEOUT=20

# ---- helpers ----

log() { echo "[$(date +%H:%M:%S)] $*"; }
die() { log "ERROR: $*" >&2; exit 1; }

month_YYYYMM() {
    date +%Y-%m
}

month_YYYY_M() {
    date +%Y-%-m
}

ensure_data_dir() {
    mkdir -p "${DATA_DIR}"
}

# yaml parser (lightweight — assumes our registry format)
# Returns: name|list|domain|category|watch_level|status
parse_list_entry() {
    local name="$1"
    awk -v NAME="$name" '
    /^\s*- name:/ { current = $NF }
    current == NAME {
        if (/list:/)       list    = $NF
        if (/domain:/)      domain  = $NF
        if (/category:/)    cat     = $NF
        if (/watch_level:/) wlevel  = $NF
        if (/status:/) {
            status = $NF
            print name "|" list "|" domain "|" cat "|" wlevel "|" status
            exit
        }
    }
    ' "$REGISTRY"
}

# ---- operations ----

fetch_list_json() {
    local list_name="$1"
    local domain="$2"
    local d_param="$3"    # YYYY-M format
    local output_file="$4"

    local url="${API_BASE}/stats.lua?list=${list_name}&domain=${domain}&d=${d_param}"
    log "Fetching: $url"

    local tmpfile
    tmpfile=$(mktemp)

    if curl -sL --max-time "$TIMEOUT" -o "$tmpfile" "$url" 2>/dev/null; then
        # Validate JSON
        if python3 -c "import json; json.load(open('$tmpfile'))" 2>/dev/null; then
            cp "$tmpfile" "$output_file"
            rm -f "$tmpfile"
            return 0
        else
            log "  WARN: Non-JSON response, skipping"
            rm -f "$tmpfile"
            return 1
        fi
    else
        log "  WARN: curl failed"
        rm -f "$tmpfile"
        return 1
    fi
}

do_status() {
    ensure_data_dir
    echo ""
    echo "=== ASF Pulse — Cache Status ==="
    echo ""

    awk '/^\s*- name:/ { print $NF }' "$REGISTRY" | while read -r name; do
        local entry
        entry=$(parse_list_entry "$name")
        [[ -z "$entry" ]] && continue

        local status
        status=$(echo "$entry" | cut -d'|' -f6)
        [[ "$status" == "inactive" ]] && continue

        local domain
        domain=$(echo "$entry" | cut -d'|' -f3)
        local watch
        watch=$(echo "$entry" | cut -d'|' -f5)

        # Find latest cached file
        local latest
        latest=$(ls -1t "${DATA_DIR}/${name}"-*.json 2>/dev/null | head -1 || true)

        if [[ -z "$latest" ]]; then
            echo "  [no cache] ${name} (${domain}) [${watch}]"
            continue
        fi

        local month_tag
        month_tag=$(basename "$latest" | sed "s/${name}-//; s/\.json$//")
        local email_count thread_count
        email_count=$(python3 -c "import json; d=json.load(open('$latest')); print(len(d.get('emails',[])))" 2>/dev/null || echo "?")
        thread_count=$(python3 -c "import json; d=json.load(open('$latest')); print(len(d.get('thread_struct',[])))" 2>/dev/null || echo "?")
        local cached_at
        cached_at=$(date -r "$latest" "+%m-%d %H:%M" 2>/dev/null || echo "?")

        printf "  %-15s %s  |  %s  |  emails: %s  threads: %s  |  cached: %s\n" \
            "${name}" "${domain}" "${watch}" "${email_count}" "${thread_count}" "${cached_at}"
    done
    echo ""
}

do_sync() {
    local target="$1"
    ensure_data_dir

    local current_YYYYMM
    current_YYYYMM=$(month_YYYYMM)
    local current_YYYY_M
    current_YYYY_M=$(month_YYYY_M)

    awk '/^\s*- name:/ { print $NF }' "$REGISTRY" | while read -r name; do
        if [[ -n "$target" ]] && [[ "$name" != "$target" ]]; then
            continue
        fi

        local entry
        entry=$(parse_list_entry "$name")
        [[ -z "$entry" ]] && continue

        local status list_name domain
        status=$(echo "$entry" | cut -d'|' -f6)
        list_name=$(echo "$entry" | cut -d'|' -f2)
        domain=$(echo "$entry" | cut -d'|' -f3)

        [[ "$status" != "active" ]] && continue

        local cache_file="${DATA_DIR}/${name}-${current_YYYYMM}.json"

        # Skip if already cached today
        if [[ -f "$cache_file" ]]; then
            local today_file today_month
            today_file=$(date +%Y-%m-%d)
            today_month=$(basename "$cache_file")
            if [[ "$(date +%Y-%m-%d)" == "${today_file}" ]]; then
                log "Skipping ${name}: already cached today"
                continue
            fi
        fi

        log "--- Syncing ${name}@${domain} ---"
        if fetch_list_json "$list_name" "$domain" "$current_YYYY_M" "$cache_file"; then
            local email_count
            email_count=$(python3 -c "import json; d=json.load(open('$cache_file')); print(len(d.get('emails',[])))" 2>/dev/null || echo "?")
            log "  Done: ${email_count} emails cached"
        else
            log "  Failed: no data returned (list may be private or restricted)"
        fi
        echo ""
    done

    log "Sync complete."
}

do_init_caches() {
    # Warm up all active lists
    log "Initializing caches for all active lists..."
    awk '/^\s*- name:/ { print $NF }' "$REGISTRY" | while read -r name; do
        local entry
        entry=$(parse_list_entry "$name")
        [[ -z "$entry" ]] && continue
        local status
        status=$(echo "$entry" | cut -d'|' -f6)
        [[ "$status" != "active" ]] && continue
        do_sync "$name"
    done
    log "Cache initialization complete."
}

# ---- main ----

main() {
    local action="${1:-}"
    local target="${2:-}"

    [[ -z "$action" ]] && { echo "Usage: $0 {--status|--sync [<name>]|--init-caches}"; exit 1; }

    case "$action" in
        --status)      do_status ;;
        --sync)        do_sync "$target" ;;
        --init-caches) do_init_caches ;;
        *)             die "Unknown action: $action" ;;
    esac
}

main "$@"
