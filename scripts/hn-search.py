#!/usr/bin/env python3
"""
HN Algolia search with retry + empty-response handling.
Usage:
  hn-search.py search <query> [--min-pts 30] [--limit 10] [--days 30]
  hn-search.py top [--min-pts 100] [--limit 20]

Returns JSON array of hits. Exits 0 even on failure (returns empty array).
"""
import sys, json, urllib.request, urllib.parse, time

HEADERS = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"}
TIMEOUT = 15
MAX_RETRY = 3


def _fetch(url):
    for attempt in range(MAX_RETRY):
        try:
            req = urllib.request.Request(url, headers=HEADERS)
            with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
                body = resp.read().decode("utf-8", errors="replace")
            if not body.strip():
                time.sleep(2 ** attempt)
                continue
            return json.loads(body)
        except (urllib.error.HTTPError, json.JSONDecodeError, TimeoutError) as e:
            time.sleep(2 ** attempt)
    return None


def search(query, min_points=30, limit=10, days=30):
    """Search HN for stories matching query with min points."""
    import calendar, time as _time
    since = int(_time.time() - days * 86400)
    params = {
        "query": query,
        "tags": "story",
        "numericFilters": f"points>{min_points},created_at_i>{since}",
        "hitsPerPage": limit,
    }
    url = "https://hn.algolia.com/api/v1/search?" + urllib.parse.urlencode(params)
    data = _fetch(url)
    if data is None:
        return []
    return data.get("hits", [])


def top(min_points=100, limit=20):
    """Get top HN stories by points (no query filter)."""
    import time as _time
    since = int(_time.time() - 7 * 86400)
    params = {
        "tags": "story",
        "numericFilters": f"points>{min_points},created_at_i>{since}",
        "hitsPerPage": limit,
        "orderBy": "points:desc",
    }
    url = "https://hn.algolia.com/api/v1/search?" + urllib.parse.urlencode(params)
    data = _fetch(url)
    if data is None:
        return []
    return data.get("hits", [])


def _fmt_hit(h):
    return {
        "points": h.get("points"),
        "comments": h.get("num_comments"),
        "title": h.get("title"),
        "url": h.get("url") or h.get("story_url"),
        "author": h.get("author"),
        "objectID": h.get("objectID"),
        "created": h.get("created_at"),
    }


if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] == "--help":
        print(__doc__)
        sys.exit(0)

    cmd = sys.argv[1]
    if cmd == "search":
        query = sys.argv[2] if len(sys.argv) > 2 else "open source"
        min_pts = int(sys.argv[sys.argv.index("--min-pts") + 1]) if "--min-pts" in sys.argv else 30
        limit = int(sys.argv[sys.argv.index("--limit") + 1]) if "--limit" in sys.argv else 10
        days = int(sys.argv[sys.argv.index("--days") + 1]) if "--days" in sys.argv else 30
        hits = search(query, min_points=min_pts, limit=limit, days=days)
    elif cmd == "top":
        min_pts = int(sys.argv[sys.argv.index("--min-pts") + 1]) if "--min-pts" in sys.argv else 100
        limit = int(sys.argv[sys.argv.index("--limit") + 1]) if "--limit" in sys.argv else 20
        hits = top(min_points=min_pts, limit=limit)
    else:
        print(f"unknown command: {cmd}", file=sys.stderr)
        sys.exit(1)

    results = [_fmt_hit(h) for h in hits]
    print(json.dumps(results, ensure_ascii=False, indent=2))
