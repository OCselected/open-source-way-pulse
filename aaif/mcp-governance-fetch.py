#!/usr/bin/env python3
"""
aaif/mcp-governance-fetch.py — MCP 治理信号采集

监控对象:
  1. MCP spec 版本列表（官方 docs markdown 索引）
  2. MCP spec 全文（GitHub raw spec markdown）
  3. MCP.directory — Server 总数 / Publisher 分布（首页 HTML 提取）
  4. MCP.directory — Top publishers（footer HTML 提取）

追踪指标:
  - spec 版本是否变化
  - spec 中合规关键词（license / compliance / conformance / sbom / copyleft）命中
  - MCP.org 下仓库数量变化
  - Publisher 分布（剩余控制权信号）

输出:
  ../data/aaif/mcp-governance-<YYYY-MM-DD>.json
  ../data/aaif/mcp-governance-latest.json (symlink)
"""

import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone, timedelta

TZ = timezone(timedelta(hours=8))
TODAY = datetime.now(TZ).strftime("%Y-%m-%d")

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PULSE_DIR = os.path.dirname(SCRIPT_DIR)
DATA_DIR = os.path.join(PULSE_DIR, "data", "aaif")
os.makedirs(DATA_DIR, exist_ok=True)

USER_AGENT = "Hermes-Pulse/1.0"
TIMEOUT = 20

# ---- helpers ----

def curl_get(url, timeout=TIMEOUT):
    try:
        req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.read().decode("utf-8", errors="replace")
    except Exception as e:
        return None


def gh_json(url):
    try:
        txt = curl_get(url)
        if txt:
            return json.loads(txt)
    except (json.JSONDecodeError, Exception):
        pass
    return None


# ---- 1. MCP spec versions ----

def fetch_mcp_spec_versions():
    """从 llms.txt 索引中提取所有 spec 版本标记。"""
    text = curl_get("https://modelcontextprotocol.io/llms.txt")
    if not text:
        return {"_error": "llms.txt fetch failed", "versions": []}

    # 索引中的文档路径含版本标记 e.g. docs/2026-07-28/...
    versions = sorted(set(re.findall(r"/docs/(\d{4}-\d{2}-\d{2})/", text)))
    # 当前版本就是最新的一个
    current = versions[-1] if versions else None
    return {"versions": versions, "current": current, "count": len(versions)}


# ---- 2. MCP spec 合规关键词扫描 ----

COMPLIANCE_KEYWORDS = [
    "license", "compliance", "conformance", "sbom", "copyleft",
    "open source compliance", "spdx", "openchain", "reciprocity",
    "gpl", "agpl", "lgpl", "mit license", "apache license",
]

def fetch_mcp_spec_compliance_scan():
    """下载最新 spec 的 3 篇核心页面，扫描合规关键词。"""
    # 从 llms.txt 索引中找 spec 相关页面
    index_text = curl_get("https://modelcontextprotocol.io/llms.txt")
    if not index_text:
        return {"_error": "index fetch failed", "hits": 0, "total": 0}

    # 提取所有 spec 路径（包含 specification/ 的）
    spec_paths = re.findall(r"(https://modelcontextprotocol.io/specification/[^\s\"]+\.md)", index_text)
    if not spec_paths:
        # fallback: 从 docs 路径中取 architecture / versioning / 基础文档
        spec_paths = [
            "https://modelcontextprotocol.io/docs/2026-07-28/learn/architecture.md",
            "https://modelcontextprotocol.io/docs/2026-07-28/learn/versioning.md",
            "https://modelcontextprotocol.io/docs/2026-07-28/learn/client-concepts.md",
            "https://modelcontextprotocol.io/docs/2026-07-28/learn/server-concepts.md",
            "https://modelcontextprotocol.io/docs/2026-07-28/tutorials/security/security_best_practices.md",
            "https://modelcontextprotocol.io/docs/2026-07-28/tutorials/security/authorization.md",
        ]

    combined = ""
    hits_detail = []
    for path in spec_paths[:10]:  # cap 10 pages
        txt = curl_get(path)
        if txt:
            combined += " " + txt
            lower = txt.lower()
            for kw in COMPLIANCE_KEYWORDS:
                if kw.lower() in lower:
                    count = lower.count(kw.lower())
                    hits_detail.append({"keyword": kw, "count": count, "page": path.split("/")[-1]})

    total_hits = sum(h["count"] for h in hits_detail)
    unique_kws = sorted(set(h["keyword"] for h in hits_detail))
    return {
        "pages_scanned": len(spec_paths[:10]),
        "total_hits": total_hits,
        "unique_keywords": unique_kws,
        "hits_detail": hits_detail[:30],  # cap detail
    }


# ---- 3. MCP.directory — 生态快照 ----

def fetch_mcp_directory():
    """从 mcp.directory 首页 HTML 提取生态数据。"""
    html = curl_get("https://mcp.directory")
    if not html:
        return {"_error": "mcp.directory fetch failed"}

    # Strip HTML tags before regex — numbers and labels are in separate <span> elements
    text = re.sub(r"<[^>]+>", " ", html)
    text = re.sub(r"\s+", " ", text)

    # 统计数字: "2,303 servers 9,291 skills 1,907 publishers 12 AI clients"
    stats_match = re.search(
        r"(\d[\d,]+)\s*servers\s+(\d[\d,]+)\s*skills\s+(\d[\d,]+)\s*publishers\s+(\d[\d,]+)\s*AI\s*clients",
        text, re.IGNORECASE,
    )
    stats = None
    if stats_match:
        stats = {
            "servers": int(stats_match.group(1).replace(",", "")),
            "skills": int(stats_match.group(2).replace(",", "")),
            "publishers": int(stats_match.group(3).replace(",", "")),
            "clients": int(stats_match.group(4).replace(",", "")),
        }

    # 从 footer "Top MCP Publishers" 提取 publisher 分布
    # 格式: <a href="/publishers/NAME">NAME<!-- --> (<!-- -->COUNT<!-- -->)</a>
    publisher_pattern = re.findall(
        r'<a[^>]*href="/publishers/([^"]+)"[^>]*>\s*([^<]+?)\s*<!--\s*-->\s*\(<!--\s*-->\s*(\d+)<!--\s*-->\s*\)',
        html,
    )
    publishers = []
    for slug, name, count in publisher_pattern:
        publishers.append({
            "slug": slug,
            "name": name.strip(),
            "server_count": int(count),
        })

    # 按 server_count 降序排列
    publishers.sort(key=lambda x: x["server_count"], reverse=True)

    # Top publishers 归属：中国 / 企业 / 个人 分类
    china_keywords = ["aliyun", "alibaba", "gongrzhe", "shanghai", "china", "tencent", "huawei", "baidu", "bytedance"]
    china_publishers = [p for p in publishers if any(k in p["slug"].lower() for k in china_keywords)]
    enterprise_keywords = ["microsoft", "google", "atlassian", "hashicorp", "anthropic", "upstash", "cloudflare"]
    enterprise_publishers = [p for p in publishers if any(k in p["slug"].lower() for k in enterprise_keywords)]

    return {
        "stats": stats,
        "total_publishers_listed": len(publishers),
        "top_publishers": publishers[:30],
        "china_publishers": china_publishers,
        "enterprise_publishers": enterprise_publishers,
    }


# ---- 4. MCP.org 仓库数量（复用已有逻辑）----

def fetch_mcp_org_summary():
    """从 GitHub API 获取 MCP org 的仓库统计。"""
    org_data = gh_json("https://api.github.com/orgs/modelcontextprotocol")
    if not org_data:
        return {"_error": "org fetch failed"}

    # repos 列表
    repos_data = gh_json("https://api.github.com/orgs/modelcontextprotocol/repos?per_page=100&sort=pushed")
    repos = []
    if repos_data:
        for r in repos_data:
            repos.append({
                "name": r.get("name"),
                "stars": r.get("stargazers_count", 0),
                "pushed": r.get("pushed_at", ""),
                "description": (r.get("description") or "")[:100],
            })

    repos.sort(key=lambda x: x.get("stars", 0), reverse=True)

    return {
        "public_repos": org_data.get("public_repos", len(repos)),
        "repos_count": len(repos),
        "repos": repos[:50],
    }


# ---- Main ----

def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "sync"

    if mode == "sync":
        print(f"[mcp-governance] Fetching MCP governance signals for {TODAY}...")

        spec_versions = fetch_mcp_spec_versions()
        print(f"  spec versions: {spec_versions.get('count', '?')} found, current={spec_versions.get('current')}")

        compliance_scan = fetch_mcp_spec_compliance_scan()
        print(f"  compliance scan: {compliance_scan.get('total_hits', 0)} hits, {len(compliance_scan.get('unique_keywords', []))} unique keywords")

        directory = fetch_mcp_directory()
        stats = directory.get("stats", {})
        print(f"  mcp.directory: {stats.get('servers', '?')} servers / {stats.get('publishers', '?')} publishers")
        china = directory.get("china_publishers", [])
        if china:
            print(f"  china publishers: {', '.join(p['name'] for p in china)}")

        org_summary = fetch_mcp_org_summary()
        print(f"  MCP.org: {org_summary.get('repos_count', '?')} repos")

        result = {
            "date": TODAY,
            "spec_versions": spec_versions,
            "compliance_scan": compliance_scan,
            "mcp_directory": directory,
            "mcp_org": org_summary,
        }

        out_path = os.path.join(DATA_DIR, f"mcp-governance-{TODAY}.json")
        with open(out_path, "w") as f:
            json.dump(result, f, ensure_ascii=False, indent=2)
        print(f"  wrote: {out_path}")

        # symlink latest (don't replace daily snapshot; only update symlink target)
        latest_path = os.path.join(DATA_DIR, "mcp-governance-latest.json")
        try:
            os.symlink(out_path, latest_path)
        except FileExistsError:
            # remove old symlink and re-create
            os.unlink(latest_path)
            os.symlink(out_path, latest_path)
        print("[mcp-governance] done.")

    elif mode == "status":
        latest = os.path.join(DATA_DIR, "mcp-governance-latest.json")
        if not os.path.exists(latest):
            print("No cached data.")
            return
        with open(latest) as f:
            d = json.load(f)
        print(json.dumps(d, ensure_ascii=False, indent=2)[:3000])

    elif mode == "diff":
        latest = os.path.join(DATA_DIR, "mcp-governance-latest.json")
        prev_candidates = sorted(
            [f for f in os.listdir(DATA_DIR) if f.startswith("mcp-governance-") and f != "mcp-governance-latest.json"],
            reverse=True,
        )
        if len(prev_candidates) < 2:
            print("Not enough cached data for diff.")
            return
        with open(os.path.join(DATA_DIR, prev_candidates[0])) as f:
            curr = json.load(f)
        with open(os.path.join(DATA_DIR, prev_candidates[1])) as f:
            prev = json.load(f)

        print(f"=== MCP Governance Diff: {prev_candidates[1][:10]} -> {prev_candidates[0][:10]} ===")
        cs = curr.get("spec_versions", {})
        ps = prev.get("spec_versions", {})
        if cs.get("current") != ps.get("current"):
            print(f"  ⚠️ SPEC VERSION CHANGE: {ps.get('current')} -> {cs.get('current')}")
        elif len(cs.get("versions", [])) != len(ps.get("versions", [])):
            print(f"  ⚠️ NEW SPEC VERSION ADDED: {len(ps.get('versions', []))} -> {len(cs.get('versions', []))}")
        else:
            print(f"  spec version stable: {cs.get('current')}")

        ch = curr.get("compliance_scan", {}).get("total_hits", 0)
        ph = prev.get("compliance_scan", {}).get("total_hits", 0)
        delta_h = ch - ph
        print(f"  compliance hits: {ph} -> {ch} ({delta_h:+d})")

        cs2 = curr.get("mcp_directory", {}).get("stats", {})
        ps2 = prev.get("mcp_directory", {}).get("stats", {})
        if cs2.get("servers") and ps2.get("servers"):
            delta_s = cs2["servers"] - ps2["servers"]
            print(f"  mcp.directory servers: {ps2['servers']} -> {cs2['servers']} ({delta_s:+d})")

    else:
        print("Usage: mcp-governance-fetch.py [sync|status|diff]")
        sys.exit(1)


if __name__ == "__main__":
    main()
