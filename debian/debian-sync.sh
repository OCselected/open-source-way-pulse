#!/usr/bin/env bash
# =============================================================================
# Project Pulse — Debian Signal Sync
# =============================================================================
#
# Fetches Debian signals from three sources:
#   1. Micronews RSS (micronews.debian.org/feeds/feed.rss) — community news
#   2. Stable Release page (debian.org/releases/stable/) — release info
#   3. debian-announce archive (lists.debian.org/debian-announce-YYYY/) — announcements
#
# Cache layout:
#   data/debian/micronews-latest.json     — Micronews RSS items (last 30 days)
#   data/debian/release-latest.json       — Stable release info
#   data/debian/announce-latest.json      — Recent debian-announce threads
#
# Usage:
#   debian-sync.sh --status    Show cached data status
#   debian-sync.sh --sync      Fetch all sources (default)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/debian"
mkdir -p "$DATA_DIR"

now_epoch() { date +%s; }
date_iso() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

TODAY=$(date +%Y-%m-%d)
CACHE_META=""

log() { echo "[debian-sync] $*"; }

# --- 1. Sync Micronews RSS ---
sync_micronews() {
    local rss_url="https://micronews.debian.org/feeds/feed.rss"
    local rss_raw="${DATA_DIR}/micronews-raw.xml"
    local output="${DATA_DIR}/micronews-latest.json"

    log "Fetching Micronews RSS..."
    timeout 15 curl -sL "$rss_url" -o "$rss_raw" 2>/dev/null || {
        log "WARN: Micronews RSS fetch failed, keeping cache"
        return 0
    }

    # Validate: must contain <rss
    if ! grep -q "<rss\|<channel\|<item" "$rss_raw"; then
        log "WARN: Invalid RSS content, keeping cache"
        return 0
    fi

    python3 - "$rss_raw" "$output" << 'PY'
import json, sys, re, xml.etree.ElementTree as ET
from datetime import datetime, timezone

raw_path = sys.argv[1]
out_path = sys.argv[2]

try:
    tree = ET.parse(raw_path)
    root = tree.getroot()
except Exception:
    print(f"WARN: cannot parse XML: {raw_path}")
    sys.exit(0)

items = []
ns = {
    "rss": "http://www.w3.org/2005/Atom",
    "dc": "http://purl.org/dc/elements/1.1",
    "content": "http://purl.org/rss/1.0/modules/content/",
}

# RSS 2.0
channel = root.find("channel")
if channel is None:
    print("WARN: no <channel> element found")
    sys.exit(0)

last_build = channel.find("lastBuildDate")
last_build_date = last_build.text if last_build is not None else ""

for item in channel.findall("item"):
    title = item.find("title")
    link = item.find("link")
    pub_date = item.find("pubDate")
    # RSS uses inline namespace (1.1/ not 1.1) — query by local name
    creator_el = None
    for child in item:
        if child.tag.endswith('}creator'):
            creator_el = child
            break
    category = item.find("category")
    guid = item.find("guid")

    items.append({
        "title": title.text if title is not None else "",
        "link": link.text if link is not None else "",
        "pub_date": pub_date.text if pub_date is not None else "",
        "creator": creator_el.text if creator_el is not None else "",
        "category": category.text if category is not None else "",
        "guid": guid.text if guid is not None else "",
    })

data = {
    "source": "micronews.debian.org",
    "fetched_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "last_build": last_build_date,
    "total_items": len(items),
    "items": items[:50],  # last 50 items
}

with open(out_path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print(f"OK: {len(items)} items cached ({len(items[:50])} in output)")
PY
}

# --- 2. Sync Stable Release info ---
sync_release() {
    local url="https://www.debian.org/releases/stable/"
    local html="${DATA_DIR}/release-raw.html"
    local output="${DATA_DIR}/release-latest.json"

    log "Fetching stable release page..."
    timeout 15 curl -sL "$url" -o "$html" 2>/dev/null || {
        log "WARN: release page fetch failed, keeping cache"
        return 0
    }

    python3 - "$html" "$output" << 'PY'
import json, sys, re
from datetime import datetime, timezone

html_path = sys.argv[1]
out_path = sys.argv[2]

with open(html_path, encoding="utf-8", errors="replace") as f:
    html = f.read()

# Extract version (e.g. "Debian 13.6")
version_match = re.search(r"Debian\s+(\d+\.\d+)", html)
version = version_match.group(1) if version_match else "unknown"

# Extract date (e.g. "2026-08-07")
date_match = re.search(r"(\d{4}-\d{2}-\d{2})", html)
date_str = date_match.group(1) if date_match else "unknown"

# Extract codename
codename_match = re.search(r"&ldquo;([^&]+)&rdquo;", html)
codename = codename_match.group(1) if codename_match else "unknown"

data = {
    "source": "debian.org/releases/stable/",
    "fetched_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "version": f"Debian {version}",
    "codename": codename,
    "release_date": date_str,
}

with open(out_path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print(f"OK: {data['version']} ({codename}) release {date_str}")
PY
}

# --- 3. Sync debian-announce archive ---
# NOTE: The announce archive at lists.debian.org returns 404 for recent years.
# The Micronews RSS (sync_micronews) is the primary data source for
# Debian community activity. This function is retained as a fallback but
# produces empty output when the server does not serve the archive.
sync_announce() {
    local year=$(date +%Y)
    local url="https://lists.debian.org/debian-announce-${year}/threads.html"
    local html="${DATA_DIR}/announce-raw.html"
    local output="${DATA_DIR}/announce-latest.json"

    log "Fetching debian-announce archive for ${year}..."
    timeout 15 curl -sL "$url" -o "$html" 2>/dev/null || {
        log "WARN: announce archive fetch failed, keeping cache"
        return 0
    }

    python3 - "$html" "$output" << 'PY'
import json, sys, re
from datetime import datetime, timezone

html_path = sys.argv[1]
out_path = sys.argv[2]

with open(html_path, encoding="utf-8", errors="replace") as f:
    html = f.read()

# Extract thread subjects: typically <a href="...">Subject</a> in table rows
subjects = []
for m in re.finditer(r'<a\s+href="([^"]+)">([^<]+)</a>', html):
    href = m.group(1)
    text = m.group(2).strip()
    # Skip navigation links
    if len(text) > 10 and not text.startswith("Previous"):
        subjects.append({
            "subject": text[:200],
            "href": href,
        })

data = {
    "source": f"lists.debian.org/debian-announce-{datetime.now().year}/",
    "fetched_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "total_threads": len(subjects),
    "threads": subjects[:30],
}

with open(out_path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print(f"OK: {len(subjects)} threads cached")
PY
}

# --- main ---
ACTION="${1:---sync}"

if [ "$ACTION" = "--status" ]; then
    echo "============================================"
    echo " Debian data cache status"
    echo "============================================"
    for f in "${DATA_DIR}/micronews-latest.json" "${DATA_DIR}/release-latest.json" "${DATA_DIR}/announce-latest.json"; do
        if [ -f "$f" ]; then
            size=$(wc -c < "$f")
            modified=$(stat -c "%y" "$f" 2>/dev/null | cut -d. -f1)
            echo "  ✓ $(basename "$f")  ${size}B  (${modified})"
        else
            echo "  ✗ $(basename "$f")  MISSING"
        fi
    done
    exit 0
fi

log "============================================"
log " Debian sync — $(date)"
log "============================================"

sync_micronews
sync_release
sync_announce

log "Done."