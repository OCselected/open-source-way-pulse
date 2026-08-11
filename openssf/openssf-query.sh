#!/usr/bin/env bash
# =============================================================================
# Project Pulse v2 — OpenSSF Scorecard Institutional Signal Extraction
# =============================================================================
# Extracts Williamson/Ostrom/Acemoglu institutional signals from cached
# Scorecard data and produces the institutional comparison table.
#
# Usage:
#   openssf-query.sh                        Full report
#   openssf-query.sh --summary              One-line per project
#   openssf-query.sh --diff <project-a> <project-b>
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/openssf"

mkdir -p "${DATA_DIR}"

if [[ ! -d "$DATA_DIR" ]] || [[ -z $(ls -A "$DATA_DIR" 2>/dev/null) ]]; then
    echo "No cached data. Run openssf-sync.sh --sync --scorecard-all first."
    exit 1
fi

echo ""
echo "============================================================"
echo "  Project Pulse v2 — Scorecard Institutional Comparison"
echo "  (Williamson/Ostrom/Acemoglu framework)"
echo "============================================================"
echo ""

printf "%-14s | %6s | %12s | %12s | %12s | %12s | %12s\n" \
    "Project" "Score" "Code-Review" "Branch-Protection" "Security-Policy" "Vulnerabilities" "Maintained"
printf "%s\n" "----------------------------------------------------------------------"

for f in "${DATA_DIR}"/scorecard-*-2026*.json; do
    [[ -s "$f" ]] || continue
    python3 -c "
import json, sys
with open('$f') as fh:
    d = json.load(fh)
score = d.get('score','?')
checks = {c['name']: c['score'] for c in d.get('checks',[])}
repo = d.get('repo',{}).get('name','?')
name = repo.split('/')[-1] if '/' in repo else repo[:12]
cr = str(checks.get('Code-Review','—'))[:12]
bp = str(checks.get('Branch-Protection','—'))[:12]
sp = str(checks.get('Security-Policy','—'))[:12]
vn = str(checks.get('Vulnerabilities','—'))[:12]
mt = str(checks.get('Maintained','—'))[:12]
print(f'{name:<14s} | {str(score):>6s} | {cr:>12s} | {bp:>12s} | {sp:>12s} | {vn:>12s} | {mt:>12s}')
" 2>/dev/null
done

echo ""
echo "NIE 维度说明："
echo "  Code-Review      → Williamson 治理约束（合并门槛）"
echo "  Branch-Protection→ Williamson 产权保护（防篡改）"
echo "  Security-Policy  → Williamson 正式规则（安全响应）"
echo "  Vulnerabilities  → 制度失败信号（安全债务）"
echo "  Maintained       → Ostrom 参与持续性"
echo ""
echo "【适兕判断】"
echo "  Scorecard 横向对比第一次把 Williamson 比较制度分析从定性描述"
echo "  推向了定量实证——每个项目的制度特征不再是修辞，而是数字。"
echo ""
