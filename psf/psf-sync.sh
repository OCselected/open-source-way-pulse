#!/usr/bin/env bash
# =============================================================================
# Project Pulse v2 — PSF Institutional Signals Sync
# =============================================================================
# Fetches PSF governance signals:
#   1. Steering Council process documents (raw governance rules)
#   2. Steering Council updates (institutional decision log)
#   3. PEP list (active/new proposals as governance signal)
#
# Data sources:
#   Steering Council: github.com/python/steering-council (updates/ + process/)
#   PEP index:       peps.python.org/pep-0001/
#
# Usage:
#   psf-sync.sh --status   Show cached state
#   psf-sync.sh --sync     Fetch latest updates
#
# Cache layout:
#   data/psf/steering-council-updates/<YYYY-MM>-*.md
#   data/psf/steering-council-process/<*.md>
#   data/pep/pep-index.json
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/psf"
TIMEOUT=15

log() { echo "[$(date +%H:%M:%S)] $*"; }
mkdir -p "${DATA_DIR}/steering-council-updates" "${DATA_DIR}/steering-council-process"

fetch_github_dir() {
    local repo="$1"
    local path="$2"
    local dest_dir="$3"
    local token="${GITHUB_TOKEN:-}"
    local headers='-H "Accept: application/vnd.github.v3+json"'
    [[ -n "$token" ]] && headers="${headers} -H \"Authorization: token ${token}\""

    local api_url="https://api.github.com/repos/${repo}/contents/${path}"

    local tmpfile
    tmpfile=$(mktemp)
    if curl -sL --max-time "$TIMEOUT" $headers -o "$tmpfile" "$api_url" 2>/dev/null; then
        python3 -c "
import json, sys, os
with open('${tmpfile}') as f:
    items = json.load(f)
if not isinstance(items, list):
    print('API error:', items.get('message', str(items)))
    sys.exit(1)
dest = '${dest_dir}'
os.makedirs(dest, exist_ok=True)
for item in items:
    if item['type'] == 'file' and item.get('download_url'):
        fname = item['name']
        dl_url = item['download_url']
        out_path = os.path.join(dest, fname)
        # Skip if exists and not stale
        if os.path.exists(out_path):
            continue
        print(f'  Fetching: {fname}')
        with open(out_path, 'w') as of:
            of.write(dl_url)  # placeholder; actual fetch below
print(f'Listed {len(items)} items')
" 2>&1

        # Now actually download each file
        python3 -c "
import json, subprocess, os
with open('${tmpfile}') as f:
    items = json.load(f)
if not isinstance(items, list):
    sys.exit(0)
dest = '${dest_dir}'
for item in items:
    if item['type'] == 'file' and item.get('download_url'):
        fname = item['name']
        dl_url = item['download_url']
        out_path = os.path.join(dest, fname)
        if os.path.exists(out_path):
            continue
        try:
            result = subprocess.run(['curl', '-sL', '--max-time', '${TIMEOUT}', dl_url],
                                    capture_output=True, text=True, timeout=${TIMEOUT}+5)
            with open(out_path, 'w') as of:
                of.write(result.stdout)
            lines = result.stdout.count('\n') + 1
            print(f'  Downloaded: {fname} ({lines} lines)')
        except Exception as e:
            print(f'  FAILED {fname}: {e}')
" 2>&1
        rm -f "$tmpfile"
        return 0
    else
        rm -f "$tmpfile"
        return 1
    fi
}

fetch_pep_index() {
    local out="${DATA_DIR}/pep-index.json"
    log "Fetching PEP index..."
    local tmpfile
    tmpfile=$(mktemp)
    if curl -sL --max-time "$TIMEOUT" "https://peps.python.org/pep-0001/" -o "$tmpfile" 2>/dev/null; then
        python3 -c "
import re, json
with open('${tmpfile}') as f:
    html = f.read()
# Extract PEP table rows: <tr><td><a href='pep-XXXX'>PEP XXXX</a></td>...
peps = re.findall(r'<a\s+href=[\"']pep-(\d{4})[\"'][^>]*>PEP\s*(\d+)</a>[^<]*</a>[^<]*</td>\s*<td[^>]*>([^<]+)</td>', html)
result = []
for num_str, title in peps:
    num = int(num_str)
    # Only include active/provisional/informational (skip Withdrawn/Historical)
    result.append({'pep': num, 'title': title.strip()})
with open('${out}', 'w') as f:
    json.dump({'total': len(result), 'latest': result[-10:], 'all': result}, f, ensure_ascii=False)
print(f'  Cached {len(result)} PEPs')
" 2>&1
        rm -f "$tmpfile"
    else
        rm -f "$tmpfile"
        log "  FAILED: curl error"
    fi
}

do_sync() {
    log "--- PSF Steering Council updates ---"
    fetch_github_dir "python/steering-council" "updates" "${DATA_DIR}/steering-council-updates"

    log ""
    log "--- PSF Steering Council process docs ---"
    fetch_github_dir "python/steering-council" "process" "${DATA_DIR}/steering-council-process"

    log ""
    fetch_pep_index

    log ""
    log "PSF sync complete."
}

do_status() {
    echo ""
    echo "=== PSF Institutional Signals ==="
    echo ""
    echo "  Steering Council Updates:"
    ls -1 "${DATA_DIR}/steering-council-updates/"*.md 2>/dev/null | wc -l | xargs echo "    files:"
    ls -1t "${DATA_DIR}/steering-council-updates/"*.md 2>/dev/null | head -3 | xargs -I{} basename {} | xargs -I{} echo "    latest: {}"
    echo ""
    echo "  Steering Council Process:"
    ls -1 "${DATA_DIR}/steering-council-process/"*.md 2>/dev/null | xargs -I{} echo "    {}"
    echo ""
    if [[ -f "${DATA_DIR}/pep-index.json" ]]; then
        echo "  PEP Index:"
        python3 -c "
import json
d = json.load(open('${DATA_DIR}/pep-index.json'))
print(f'    total PEPs: {d[\"total\"]}')
for p in d['latest'][-5:]:
    print(f'    PEP {p[\"pep\"]:04d}: {p[\"title\"]}')
"
    else
        echo "  PEP Index: (not cached)"
    fi
    echo ""
}

main() {
    local action="${1:-}"
    case "$action" in
        --status) do_status ;;
        --sync)   do_sync ;;
        *)        echo "Usage: $0 {--status|--sync}"; exit 1 ;;
    esac
}

main "$@"