#!/usr/bin/env bash
# =============================================================================
# Project Pulse v2 — OSV 记录配额（谁在往公共漏洞库里写）Institutional Sync
# Data sources:
#   - GCS 对象清单: osv-vulnerabilities bucket（先计数，不下载）
#   - GCS 逐条记录: database_specific.malicious-packages-origins（写入方归属）
#   - 单条 API: https://api.osv.dev/v1/vulns/<ID>
#   - GitHub advisories 页面读数（平台口径对照）
# Institutional framing: 「漏洞库的构成 = 一张『谁在往公地写记录』的地图」。
#   OSV 的 malicious-packages-origins 把每条恶意记录归属到具体 scanner，这是
#   比 GHSA（reporter 不公开）更可归属的公共记录设计 —— 「要求公共记录带写入方
#   字段」因此是可立即实施、成本极低的制度设计动作。
# NIE 轴：Coase（检测被外包给多方）/ Williamson（无准入标准的多方写入共享基础设施）
#         / North（写入方结构变迁 + fixed 覆盖率单调改善 vs 监管追溯义务）
#         / Ostrom（公地投入的可归属化 = 监督原则的技术前提）
#         / A&R（归属字段的包容性；同一生态两套透明度标准并存）
# 2026-10-27 队列评估 P0 落地（队列 2026-10-21 ~ 2026-10-27）。
#
# 用法：
#   --sync            全量同步（计数 + 抽样 origin + 平台口径对照）
#   --count           仅 GCS 对象计数（最快，不下载任何记录体）
#   --origins <year>  对某年份段抽样统计 origin 归属（默认 2025）
#   --status          查看缓存
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/osv-origins"
TODAY=$(date +%Y-%m-%d)
TIMEOUT=45
UA="Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0"
GCS_API="https://storage.googleapis.com/storage/v1/b/osv-vulnerabilities/o"

mkdir -p "${DATA_DIR}"

log() { echo "[$(date +%H:%M:%S)] $*"; }

# --- 1. GCS 对象计数（权威基数，不下载记录体）--------------------------------
do_count() {
    local out="${DATA_DIR}/object-count-${TODAY}.json"
    if [[ -f "$out" ]]; then log "(cached) object-count ${TODAY}"; return; fi
    log "Counting GCS objects (pagination only, no downloads)..."
    python3 - "$out" <<'PY'
import json, sys, urllib.request, urllib.parse, datetime
UA = {'User-Agent': 'Mozilla/5.0 (compatible; pulse-cron)'}
BASE = "https://storage.googleapis.com/storage/v1/b/osv-vulnerabilities/o"

def count(prefix):
    tok, n = None, 0
    while True:
        u = f"{BASE}?prefix={urllib.parse.quote(prefix)}&maxResults=1000&fields=items(name),nextPageToken"
        if tok:
            u += f"&pageToken={tok}"
        d = json.load(urllib.request.urlopen(urllib.request.Request(u, headers=UA), timeout=45))
        n += len(d.get('items', []))
        tok = d.get('nextPageToken')
        if not tok:
            return n

doc = {"as_of": datetime.date.today().isoformat()}
for label, prefix in [
    ("npm_mal_2025", "npm/MAL-2025-"),
    ("npm_mal_2026", "npm/MAL-2026-"),
]:
    doc[label] = count(prefix)
    print(f"  {label}: {doc[label]}")
doc["npm_mal_total"] = doc["npm_mal_2025"] + doc["npm_mal_2026"]
json.dump(doc, open(sys.argv[1], 'w'), indent=2)
print(f"  npm_mal_total: {doc['npm_mal_total']}")
PY
    echo "$(date -Iseconds) npm_mal_total=$(python3 -c "import json;print(json.load(open('${out}'))['npm_mal_total'])" 2>/dev/null || echo '?')" \
        >> "${DATA_DIR}/object-count.history"
    log "  Saved ${out}"
}

# --- 2. origin 归属抽样（核心证据）-------------------------------------------
# **ID 序 ≠ 时间序**（2026-10-27 实测教训）：amazon-inspector 的记录在 ID 空间里
# 成块聚集（npm/MAL-2025-60000..180000 连续三段 100% 是它），因此任何连续前缀
# 取样都会得到一个假的占比。正确做法是**按 published 月份分层抽样**（随机抽取
# 稀疏 ID），既能给出时间序列，也能避免前缀聚集偏差。本脚本默认做分层抽样。
do_origins() {
    local year="${1:-2026}"
    local out="${DATA_DIR}/origins-${year}-${TODAY}.json"
    if [[ -f "$out" ]]; then log "(cached) origins ${year} ${TODAY}"; return; fi
    log "Stratified sampling of malicious-packages-origins for ${year} (by published month)..."
    python3 - "$year" "$out" <<'PY'
import json, sys, urllib.request, urllib.parse, concurrent.futures, collections, datetime, random
YEAR, OUT = sys.argv[1], sys.argv[2]
UA = {'User-Agent': 'Mozilla/5.0 (compatible; pulse-cron)'}
BASE = "https://storage.googleapis.com/storage/v1/b/osv-vulnerabilities/o"
SAMPLE_N = 12000          # 随机抽取的 ID 数量（稀疏抽样，规避 ID 分块聚集）
MAX_WORKERS = 24

def list_ids(prefix):
    tok, names = None, []
    while True:
        u = f"{BASE}?prefix={urllib.parse.quote(prefix)}&maxResults=1000&fields=items(name),nextPageToken"
        if tok:
            u += f"&pageToken={tok}"
        d = json.load(urllib.request.urlopen(urllib.request.Request(u, headers=UA), timeout=45))
        names.extend(i['name'] for i in d.get('items', []))
        tok = d.get('nextPageToken')
        if not tok:
            return names

def fetch(name):
    u = f"{BASE}/{urllib.parse.quote(name, safe='')}?alt=media"
    try:
        return json.load(urllib.request.urlopen(urllib.request.Request(u, headers=UA), timeout=30))
    except Exception:
        return None

all_ids = list_ids(f"npm/MAL-{YEAR}-")
total = len(all_ids)
random.seed(20261027)
sample = all_ids if total <= SAMPLE_N else random.sample(all_ids, SAMPLE_N)

by_month = collections.defaultdict(collections.Counter)
month_records = collections.Counter()
fetched = errors = no_origin = 0
with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as ex:
    for rec in ex.map(fetch, sample):
        if not rec:
            errors += 1
            continue
        fetched += 1
        month = str(rec.get('published', ''))[:7] or 'unknown'
        month_records[month] += 1
        ds = rec.get('database_specific', {}) or {}
        os_ = ds.get('malicious-packages-origins') or []
        if not os_:
            no_origin += 1
        for o in os_:
            by_month[month][o.get('source', '?')] += 1

def shares(c):
    s = sum(c.values()) or 1
    return {k: round(v / s, 4) for k, v in c.most_common()}

doc = {
    "as_of": datetime.date.today().isoformat(),
    "year": YEAR,
    "prefix_total": total,
    "sampled_requested": len(sample),
    "sampled_fetched": fetched,
    "fetch_errors": errors,
    "records_without_origin": no_origin,
    "sampling": "random (seed 20261027) — 避开 ID 分块聚集，非连续前缀",
    "by_month": {
        m: {"records_sampled": month_records[m],
            "origin_counts": dict(by_month[m]),
            "origin_share": shares(by_month[m])}
        for m in sorted(by_month)
    },
}
json.dump(doc, open(OUT, 'w'), indent=2, ensure_ascii=False)
print(f"  prefix_total={total} sampled={fetched} errors={errors} no_origin={no_origin}")
for m in sorted(by_month):
    c = by_month[m]; s = sum(c.values()) or 1
    print(f"    {m} ({month_records[m]} recs): " + ', '.join(f"{k}:{v/s*100:.0f}%" for k, v in c.most_common(4)))
PY
    log "  Saved ${out}"
}

# --- 3. 平台口径对照 ---------------------------------------------------------
do_platform() {
    local out="${DATA_DIR}/platform-counts-${TODAY}.txt"
    if [[ -f "$out" ]]; then log "(cached) platform-counts ${TODAY}"; return; fi
    log "Fetching GitHub advisories page reading..."
    {
        echo "as_of: $(date -Iseconds)"
        echo "--- npm/all.zip (via HEAD) ---"
        curl -sI --max-time ${TIMEOUT} -A "${UA}" \
            "https://osv-vulnerabilities.storage.googleapis.com/npm/all.zip" \
            | grep -iE '^(content-length|x-goog-stored-content-length|last-modified)' || echo "  (headers unavailable)"
        echo ""
        echo "--- github/advisories?query=type:reviewed ---"
        if curl -sfL --max-time ${TIMEOUT} -A "${UA}" \
            "https://github.com/advisories?query=type%3Areviewed" -o "${DATA_DIR}/.ghadv.tmp"; then
            grep -oiE '[0-9,]+ reviewed advisories' "${DATA_DIR}/.ghadv.tmp" | head -1 || echo "  (count pattern not found)"
            rm -f "${DATA_DIR}/.ghadv.tmp"
        else
            echo "  FAILED"
        fi
    } > "$out"
    log "  Saved ${out}"
}

do_status() {
    echo ""
    echo "=== OSV Origins Institutional Signals Cache ==="
    echo ""
    echo "Files: $(find "${DATA_DIR}" -maxdepth 1 -type f 2>/dev/null | wc -l)  (${DATA_DIR})"
    echo ""
    find "${DATA_DIR}" -maxdepth 1 -type f -printf "%T@ %f\n" 2>/dev/null | sort -rn | head -10 \
        | while read -r _ts fname; do
            printf "  %-42s %8d bytes\n" "$fname" "$(wc -c < "${DATA_DIR}/${fname}")"
        done
    echo ""
    [[ -f "${DATA_DIR}/object-count.history" ]] && { echo "--- object-count history ---"; tail -10 "${DATA_DIR}/object-count.history"; echo ""; }
}

main() {
    case "${1:-}" in
        --sync)
            do_count
            do_origins 2025
            do_platform
            ;;
        --count) do_count ;;
        --origins) do_origins "${2:-2025}" ;;
        --status) do_status ;;
        *) echo "Usage: $0 {--sync|--count|--origins <year>|--status}"; exit 1 ;;
    esac
}

main "$@"
