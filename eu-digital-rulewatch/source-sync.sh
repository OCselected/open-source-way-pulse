#!/usr/bin/env bash
# =============================================================================
# Project Pulse v2 — EU Digital Rulewatch Sync
# 三个制度文本发布渠道的合流观测面：
#   ① Regulation & Governance (Wiley) — 学术期刊 Early View（RSS）
#   ② RegulAite (Univ. of Amsterdam) — 政策过程研究工作论文（HTML 结构）
#   ③ CyberBRICS (FGV/CTS)        — 全球南方数字主权研究（WP REST API，含 PDF）
#
# 为什么合流：三者各占「规则在法层之间迁移」的一条线 ——
#   期刊=谁在游说/谁在写、研究项目=委托与控制如何运作、南方机构=同一概念的另一法域形态。
#   单独任一家都只是信息流；合起来才能检验「规则的稳定性来自层级而非内容」。
#
# 已实测的坑（勿重复踩）：
#   - onlinelibrary.wiley.com 整刊页 curl 403，但 /feed/<issn>/most-recent 返回 200 XML
#     → 唯一可用入口是 RSS；Crossref 期刊 API 只能拿元数据，拿不到正文
#   - regulaite.eu 无 RSS、无 wp-json、无 sitemap（三路径全 404）
#     → 只能按 HTML 的 `Published:` 结构解析；且列表是固定 20 条的滚动窗口
#   - cyberbrics.info 的 `/publications/` 是 404，正确入口是 category id=12
#     → 用 wp-json/wp/v2/posts?categories=12；条目正文内含 PDF 直链
#   - MPPE (www.wi.tum.de) 本机不可达（超时，DNS 通），不进自动化管线，见 registry 的 P1 记录
#
# 2026-10-28 队列评估 P0 落地
# NIE 轴：North（软法→硬法的层级迁移）/ Williamson（监管对标准组织的委托-控制）
#         / A&R（谁能书写南方样本）/ Coase（开放权重作为出口管制与边界的工具）
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/eu-digital-rulewatch"
TODAY=$(date +%Y-%m-%d)
TIMEOUT=30
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36"

mkdir -p "${DATA_DIR}"

log() { echo "[$(date +%H:%M:%S)] $*"; }

# --- 1. Regulation & Governance（Wiley RSS） ------------------------------
sync_wiley() {
    local out="${DATA_DIR}/wiley-rego-${TODAY}.xml"
    if [[ -f "$out" ]]; then log "(cached) Wiley RSS"; return; fi
    log "Fetching Regulation & Governance most-recent feed ..."
    curl -sfL --max-time "${TIMEOUT}" -A "${UA}" \
        "https://onlinelibrary.wiley.com/feed/17485991/most-recent" -o "$out" \
        && log "  Saved ($(wc -c < "$out") bytes)" \
        || { log "  FAILED (403? Cloudflare)"; rm -f "$out"; }
}

# --- 2. RegulAite（HTML 结构） --------------------------------------------
sync_regulaite() {
    local out="${DATA_DIR}/regulaite-publications-${TODAY}.html"
    if [[ -f "$out" ]]; then log "(cached) RegulAite page"; return; fi
    log "Fetching RegulAite publications ..."
    curl -sfL --max-time "${TIMEOUT}" -A "${UA}" \
        "https://www.regulaite.eu/output/publications/" -o "$out" \
        && log "  Saved ($(wc -c < "$out") bytes)" \
        || { log "  FAILED"; rm -f "$out"; }
}

# --- 3. CyberBRICS（WP REST API） ----------------------------------------
sync_cyberbrics() {
    local out="${DATA_DIR}/cyberbrics-publications-${TODAY}.json"
    if [[ -f "$out" ]]; then log "(cached) CyberBRICS API"; return; fi
    log "Fetching CyberBRICS publications (category 12) ..."
    curl -sfL --max-time "${TIMEOUT}" -A "${UA}" \
        "https://cyberbrics.info/wp-json/wp/v2/posts?categories=12&per_page=30&_fields=id,date,link,title,content" -o "$out" \
        && log "  Saved ($(wc -c < "$out") bytes)" \
        || { log "  FAILED"; rm -f "$out"; }
}

# --- 4. 归一化 + 关键词画像 ----------------------------------------------
do_verify() {
    local out="${DATA_DIR}/verification-${TODAY}.json"
    log "Normalising three channels ..."
    python3 - "$DATA_DIR" "$TODAY" "$out" <<'PY'
import json, re, sys, glob, html as htmllib

data_dir, today, out_path = sys.argv[1:4]

# 制度关键词：判据是「这条内容是否直接落在规则层级/治理结构上」
KW = {
    'open_source':   r'\bopen[- ]source|\bFOSS\b|\bFLOSS\b',
    'licensing':     r'\blicen[cs]|\broyalty[- ]free\b|\bFRAND\b|\bcopyleft\b',
    'standardization': r'\bstandardi[sz]',
    'platform_gov':  r'\bplatform\b.*\bgovernance|\bDSA\b|\bDMA\b',
    'ai_act':        r'\bAI Act\b|\bCRA\b|\bCyber Resilience\b',
    'sovereignty':   r'\bsovereignt',
    'sandbox':       r'\bsandbox|\bregulatory (privilege|experiment)',
}

def profile(text):
    low = text.lower()
    return {k: bool(re.search(p, low, re.I)) for k, p in KW.items()}

channels = {}

# --- Wiley RSS
files = sorted(glob.glob(f"{data_dir}/wiley-rego-*.xml"))
if files:
    raw = open(files[-1], encoding='utf-8', errors='ignore').read()
    items = re.findall(r'<item>(.*?)</item>', raw, re.S)
    recs = []
    for it in items:
        t = re.search(r'<title>(.*?)</title>', it, re.S)
        d = re.search(r'<pubDate>(.*?)</pubDate>', it, re.S)
        l = re.search(r'<link>(.*?)</link>', it, re.S)
        title = htmllib.unescape(re.sub(r'\s+', ' ', re.sub(r'<[^>]+>', '', t.group(1)))).strip() if t else ''
        recs.append({
            'title': title,
            'date_raw': d.group(1).strip() if d else None,
            'link': l.group(1).strip() if l else None,
            'doi': (re.search(r'(10\.\d{4,}/[^\s?&]+)', l.group(1)).group(1)
                    if l and re.search(r'(10\.\d{4,}/[^\s?&]+)', l.group(1)) else None),
            **profile(title),
        })
    channels['regulation_and_governance'] = {
        'items_total_in_feed': len(recs),
        'relevant': [r for r in recs if any(v for k, v in r.items() if k in KW)],
        'latest_5': recs[:5],
    }

# --- RegulAite
files = sorted(glob.glob(f"{data_dir}/regulaite-publications-*.html"))
if files:
    raw = open(files[-1], encoding='utf-8', errors='ignore').read()
    # 每个条目以 "Written by:" 分隔，日期形如 "Published: 27 May 2026"
    blocks = raw.split('Written by:')[1:]
    recs = []
    for b in blocks:
        text = htmllib.unescape(re.sub(r'<[^>]+>', ' ', b))
        text = re.sub(r'\s+', ' ', text)
        dm = re.search(r'Published:\s*([0-9]{1,2} [A-Za-z]+ [0-9]{4})', text)
        doi = re.search(r'https://doi\.org/(\S+?)(?:\s|$)', b)
        # 标题在 Cited-by 之外的那一段：优先取「引号内被拆开的短语」，
        # 因为 RegulAite 把论文标题放在两个引号之间且中间夹着链接标签。
        # 实测页面结构：slug 行 → 作者行 → 带引号标题 → 期刊名/DOI → Details → Published
        slug = re.search(r'^\s*([A-Z][A-Za-z0-9\.&;\-]*.*?)\s*Category:', text)
        quoted = re.findall(r'[“"]([^”"]{12,180})[”"]', text)
        if quoted:
            title = max(quoted, key=len)
            title = re.sub(r'\s+', ' ', title).strip()
        else:
            # 退化路径：Published 之前最后一段可读文本
            pre = text.split('Published:')[0].strip()
            title = pre[-160:] if pre else text[:120]
        recs.append({
            'title': title[:160],
            'slug_line': slug.group(1)[:80] if slug else None,
            'published': dm.group(1) if dm else None,
            'doi': doi.group(1) if doi else None,
            **profile(title + ' ' + text[:600]),
        })
    channels['regulaite'] = {
        'items_total_on_page': len(recs),
        'relevant': [r for r in recs if any(v for k, v in r.items() if k in KW)],
        'latest_5': recs[:5],
    }

# --- CyberBRICS
files = sorted(glob.glob(f"{data_dir}/cyberbrics-publications-*.json"))
if files:
    d = json.load(open(files[-1]))
    recs = []
    for p in d:
        title = htmllib.unescape(re.sub(r'<[^>]+>', '', p['title']['rendered'])).strip()
        pdfs = re.findall(r'href="([^"]+\.pdf)"', p['content']['rendered'])
        recs.append({
            'title': title,
            'date': p['date'][:10],
            'link': p['link'],
            'pdf': pdfs[0] if pdfs else None,
            **profile(title),
        })
    channels['cyberbrics'] = {
        'items_fetched': len(recs),
        'relevant': [r for r in recs if any(v for k, v in r.items() if k in KW)],
        'latest_5': recs[:5],
    }

rec = {'date': today, 'channels': channels,
       'keyword_set': list(KW.keys()),
       'note': 'relevant = 标题命中制度关键词集合；正文级判断需人工/LLM，脚本只做筛子'}
json.dump(rec, open(out_path, 'w'), indent=1, ensure_ascii=False)

for name, ch in channels.items():
    n_rel = len(ch['relevant'])
    print(f"  {name}: 采集 {ch.get('items_total_in_feed') or ch.get('items_total_on_page') or ch.get('items_fetched')} 条 | 关键词命中 {n_rel}")
    for r in ch['latest_5'][:3]:
        dt = r.get('date') or r.get('published') or (r.get('date_raw') or '')[:16]
        print(f"      {dt} | {r['title'][:78]}")
PY
}

# --- 5. 提取报告 -----------------------------------------------------------
do_extract() {
    echo ""
    echo "=== EU Digital Rulewatch — 规则所在的法层 ==="
    local v
    v=$(ls -1t "${DATA_DIR}"/verification-*.json 2>/dev/null | head -1 || true)
    if [[ -z "$v" ]]; then echo "- ⚠️ 无 verification 记录（先跑 --sync && --verify）"; echo ""; return; fi
    python3 - "$v" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
print(f"- 关键词集合: {', '.join(d['keyword_set'])}")
for name, ch in d['channels'].items():
    total = ch.get('items_total_in_feed') or ch.get('items_total_on_page') or ch.get('items_fetched')
    print(f"- {name}: {total} 条 | 制度关键词命中 {len(ch['relevant'])}")
    for r in ch['relevant'][:2]:
        dt = r.get('date') or r.get('published') or (r.get('date_raw') or '')[:16]
        print(f"    · {dt} {r['title'][:90]}")
        if r.get('doi'):
            print(f"      DOI {r['doi']}")
print("- 判据: 同一规则从软法搬进硬法 = 稳定性来自层级；本模块提供期刊/研究/南方三条独立读数")
print("")
PY
}

do_status() {
    echo ""
    echo "=== EU Digital Rulewatch Cache ==="
    echo "  Total cached: $(find "${DATA_DIR}" -maxdepth 1 -type f 2>/dev/null | wc -l)"
    find "${DATA_DIR}" -maxdepth 1 -type f -printf "%T@ %f\n" 2>/dev/null \
        | sort -rn | head -8 | while read -r _ts fname; do
            printf "  %-44s %8d bytes\n" "$fname" "$(wc -c < "${DATA_DIR}/${fname}")"
        done
    echo ""
}

main() {
    case "${1:-}" in
        --sync)
            sync_wiley
            sync_regulaite
            sync_cyberbrics
            ;;
        --verify)  do_verify ;;
        --extract) do_extract ;;
        --status)  do_status ;;
        *) echo "Usage: $0 {--sync|--verify|--extract|--status}"; exit 1 ;;
    esac
}

main "$@"
