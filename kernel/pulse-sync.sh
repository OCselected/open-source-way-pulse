#!/usr/bin/env bash
# pulse-sync.sh — sync open-source-way-pulse inbox repos.
#
# Strategy:
#   - Each inbox's latest epoch lives at repos/inboxes/<name>/
#     (git-bare clone from lore.kernel.org/<inbox>/<epoch>)
#   - Daily: git pull --all (incremental, fast)
#   - Epoch bump detection: lore.kernel.org uses Anubis PoW,
#     so curl cannot fetch the mirror page. Epoch bumps are
#     handled manually (user tells us, or we check via browser).
#
# Usage:
#   bash pulse-sync.sh              # sync all active inboxes
#   bash pulse-sync.sh --inbox lkml # sync a single inbox
#   bash pulse-sync.sh --status     # show status of all inboxes
#   bash pulse-sync.sh --help

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REGISTRY="$PULSE_DIR/kernel/registry.yaml"
INBOX_DIR="$PULSE_DIR/repos/inboxes"

ACTION="${1:-sync}"

mkdir -p "$INBOX_DIR"

# Simple yaml parser (no external deps)
get_field() {
  local target_name="$1" field="$2"
  awk -v name="$target_name" -v f="$field" '
    $0 ~ "- name:" { cur=0 }
    $0 ~ "- name: " name { cur=1 }
    cur && $0 ~ f":" {
      sub(/^[^:]+:[ \t]*/, "")
      gsub(/[ \t]+$/, "")
      print
    }
  ' "$REGISTRY"
}

# Display status
if [ "$ACTION" = "--status" ]; then
  echo "============================================"
  echo " Project Pulse — inbox status"
  echo "============================================"
  while IFS= read -r name; do
    lore="$(get_field "$name" lore)"
    status="$(get_field "$name" status)"
    epoch="$(get_field "$name" latest_epoch)"
    desc="$(get_field "$name" description)"
    dest="$INBOX_DIR/$name"
    count=""
    newest=""
    if [ -d "$dest/.git" ]; then
      count="$(cd "$dest" && git rev-list --all --count 2>/dev/null || echo '?')"
      newest="$(cd "$dest" && git log --format='%ai' -1 2>/dev/null || echo '?')"
    fi
    echo "  [$status] $name (lore: $lore, epoch: $epoch)"
    echo "    $desc"
    echo "    emails: $count | newest: $newest"
  done < <(grep -oP '^\s+- name:\s+\K\S+' "$REGISTRY")
  echo "============================================"
  exit 0
fi

if [ "$ACTION" = "--help" ]; then
  echo "Usage: pulse-sync.sh [action] [options]"
  echo ""
  echo "Actions:"
  echo "  (none) | --inbox <name>   Sync inbox(es)"
  echo "  --status                  Show status of all inboxes"
  echo "  --help                    This message"
  echo ""
  echo "Inboxes:"
  grep -oP '^\s+- name:\s+\K\S+' "$REGISTRY" | while read -r n; do
    echo "  - $n ($(get_field "$n" description))"
  done
  exit 0
fi

# Determine which inboxes to sync
if [ "$ACTION" = "--inbox" ]; then
  TARGETS="${2:-}"
elif [ "$ACTION" = "sync" ]; then
  TARGETS=$(grep -oP '^\s+- name:\s+\K\S+' "$REGISTRY")
else
  echo "Unknown action: $ACTION" >&2
  exit 1
fi

echo "============================================"
echo " Project Pulse — inbox sync"
echo " $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "============================================"

for name in $TARGETS; do
  lore="$(get_field "$name" lore)"
  status="$(get_field "$name" status)"
  epoch="$(get_field "$name" latest_epoch)"
  desc="$(get_field "$name" description)"
  dest="$INBOX_DIR/$name"

  echo ""
  echo "--- [$status] $name ($desc) ---"

  if [ "$status" = "inactive" ]; then
    echo "  SKIPPED (inactive)"
    continue
  fi

  if [ ! -d "$dest/.git" ]; then
    echo "  NOT YET CLONED — run clone manually:"
    echo "  git clone --bare https://lore.kernel.org/$lore/$epoch $dest"
    continue
  fi

  echo "  Syncing (epoch $epoch)..."
  before="$(cd "$dest" && git rev-list --all --count 2>/dev/null || echo 0)"
  # Bare repos: fetch instead of pull (pull requires a work tree)
  (cd "$dest" && git fetch origin 2>&1 | tail -1) || true
  after="$(cd "$dest" && git rev-list --all --count 2>/dev/null || echo 0)"
  new=$((after - before))
  newest="$(cd "$dest" && git log --format='%ai %s' -1 2>/dev/null)"
  echo "  +$new emails | total: $after | latest: $newest"
done

echo ""
echo "============================================"
echo " Sync complete. $(date '+%Y-%m-%d %H:%M:%S %Z')"
