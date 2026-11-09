#!/usr/bin/env bash
# pulse-run-all.sh — Project Pulse 数据采集一键脚本
# 用途：把原本 17 次独立工具调用（11 查询 + 6 同步）压缩为 1 次调用。
# 设计：单条命令失败不中断整体；全部输出写入 /tmp/pulse-report.txt；
#       终端只回显简短确认 + 文件路径，模型用 read_file 读取全文（避免大输出被截断）。
# 同步有缓存时幂等，可安全重试。
set +e

cd /home/lee/developing/open-source-way-pulse || exit 1
OUT=/tmp/pulse-report.txt

{
echo "===== Project Pulse 数据采集  $(date '+%Y-%m-%d %H:%M %Z') ====="
echo ""

echo "########## PART 1: Linux Kernel (lkml) ##########"
bash kernel/pulse-sync.sh 2>&1 | tail -3
bash kernel/pulse-query.sh lkml --days 7 2>&1
echo ""

echo "########## PART 1b: Git (lore.kernel.org/git) ##########"
bash kernel/pulse-sync.sh --inbox git 2>&1 | tail -3
bash git/git-query.sh --days 7 2>&1
echo ""

echo "########## PART 2: Apache Software Foundation ##########"
bash asf/asf-sync.sh --sync 2>&1 | tail -5
bash asf/asf-query.sh 2>&1
echo ""

echo "########## PART 3: Agentic AI Foundation (AAIF) ##########"
python3 aaif/fetch.py sync 2>&1 | tail -8
python3 aaif/mcp-governance-fetch.py sync 2>&1 | tail -8
bash aaif/aaif-query.sh 2>&1
echo ""

echo "########## PART 3b: AI Infra (K8s / PyTorch / vLLM / SGLang) ##########"
python3 k8s/github-sync.py sync 2>&1 | tail -5
bash k8s/k8s-query.sh 2>&1
bash pytorch/pytorch-query.sh 2>&1
bash vllm/vllm-query.sh 2>&1
bash sglang/sglang-query.sh 2>&1
echo ""

echo "########## PART 4: Python / LLVM / Debian ##########"
python3 python/discourse-sync.py 2>&1 | tail -5
python3 k8s/github-sync.py sync python 2>&1 | tail -3
python3 k8s/github-sync.py sync llvm 2>&1 | tail -3
bash python/python-query.sh 2>&1
bash llvm/llvm-query.sh 2>&1
bash debian/debian-query.sh 2>&1
echo ""

echo "########## PART 5: Bounty Ledger (curl vuln.pm 定价台账) ##########"
bash bounty-ledger/source-sync.sh --sync 2>&1 | tail -3
bash bounty-ledger/source-sync.sh --verify 2>&1
echo ""

echo "===== 采集完成 $(date '+%Y-%m-%d %H:%M %Z') ====="
} >> "$OUT" 2>&1

echo "DONE path=$OUT lines=$(wc -l < "$OUT") bytes=$(wc -c < "$OUT")"
