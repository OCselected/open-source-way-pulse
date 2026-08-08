#!/usr/bin/env python3
"""
cf-avoid.py — Fetch open-source news via sources that bypass Cloudflare.

Data sources (verified working 2026-08-08):
  - Google News RSS (primary, works reliably)
  - CNCF blog RSS (https://www.cncf.io/blog/feed/)
  - HN Algolia (via hn-search.py)

Usage:
  cf-avoid.py lf [--days 7]     — Linux Foundation news
  cf-avoid.py cncf [--days 7]   — CNCF / Kubernetes / Cloud Native news
  cf-avoid.py apache [--days 7] — Apache Software Foundation news
  cf-avoid.py all [--days 7]    — Combined broad open-source news
  cf-avoid.py hn [--min-pts 30] [--limit 10] [--days 7] — Hacker News

Returns JSON. Exits 0 even on partial failure.
"""
import sys, json, urllib.request, urllib.parse, time
import xml.etree.ElementTree as ET

HEADERS = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"}
TIMEOUT = 12
MAX_RETRY = 2


def _fetch(url):
    for attempt in range(MAX_RETRY):
        try:
            req = urllib.request.Request(url, headers=HEADERS)
            with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
                return resp.read().decode("utf-8", errors="replace")
        except Exception:
            time.sleep(2 ** attempt)
    return None


def _parse_rss(xml):
    if not xml:
        return []
    try:
        root = ET.fromstring(xml)
        items = root.findall(".//item")
        results = []
        for item in items:
            results.append({
                "title": (item.findtext("title") or "").strip(),
                "pubDate": (item.findtext("pubDate") or "").strip(),
                "source": (item.findtext("source") or "").strip(),
                "link": (item.findtext("link") or "").strip(),
            })
        return results
    except ET.ParseError:
        return []


def gnews(query, days=7):
    """Fetch Google News RSS for a query."""
    q = urllib.parse.quote(query)
    url = (f"https://news.google.com/rss/search?q={q}&"
           f"hl=en-US&gl=US&ceid=US:en")
    xml = _fetch(url)
    return _parse_rss(xml)


def cncf_feed():
    """CNCF blog RSS (works directly, no Cloudflare)."""
    xml = _fetch("https://www.cncf.io/blog/feed/")
    return _parse_rss(xml)


def hn_search(query, min_points=30, limit=10, days=7):
    """Delegate to hn-search.py."""
    import subprocess
    try:
        r = subprocess.run(
            [sys.executable, sys.argv[0].replace("cf-avoid", "hn-search"),
             "search", query, "--min-pts", str(min_points),
             "--limit", str(limit), "--days", str(days)],
            capture_output=True, text=True, timeout=60)
        return json.loads(r.stdout) if r.returncode == 0 else []
    except Exception:
        return []


def lf(days=7):
    return gnews("linux foundation open source", days=days)


def cncf(days=7):
    out = gnews("cncf kubernetes cloud native linux foundation", days=days)
    # Deduplicate with CNCF blog feed
    feed = cncf_feed()
    seen = {i["title"] for i in out}
    for f in feed:
        if f["title"] and f["title"] not in seen:
            out.append(f)
            seen.add(f["title"])
    return out


def apache(days=7):
    return gnews("apache software foundation open source", days=days)


def all_(days=7):
    return gnews(
        "linux foundation OR cncf OR kubernetes OR apache software foundation "
        "OR open source initiative OR mozilla foundation OR gitlab OR debian "
        "OR python software foundation", days=days)


if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] == "--help":
        print(__doc__)
        sys.exit(0)

    cmd = sys.argv[1]
    days = int(sys.argv[sys.argv.index("--days") + 1]) if "--days" in sys.argv else 7

    if cmd == "lf":
        results = lf(days)
    elif cmd == "cncf":
        results = cncf(days)
    elif cmd == "apache":
        results = apache(days)
    elif cmd == "hn":
        query = sys.argv[2] if len(sys.argv) > 2 else "open source"
        min_pts = int(sys.argv[sys.argv.index("--min-pts") + 1]) if "--min-pts" in sys.argv else 30
        limit = int(sys.argv[sys.argv.index("--limit") + 1]) if "--limit" in sys.argv else 10
        results = hn_search(query, min_points=min_pts, limit=limit, days=days)
    elif cmd == "all":
        results = all_(days)
    else:
        print(f"unknown command: {cmd}", file=sys.stderr)
        sys.exit(1)

    print(json.dumps(results, ensure_ascii=False, indent=2))
