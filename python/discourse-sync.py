#!/usr/bin/env python3
"""Sync Discourse forum data for Python project."""
import os, sys, json, urllib.request, time

BASE = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DATA = os.path.join(BASE, "data")
CACHE = os.path.join(DATA, "discourse-python", "latest.json")
URL = "https://discuss.python.org/latest.json"
HEADERS = {"User-Agent": "ProjectPulse/1.0"}

def sync(force=False):
    os.makedirs(os.path.dirname(CACHE), exist_ok=True)
    if os.path.exists(CACHE) and not force and (time.time()-os.path.getmtime(CACHE))<3600:
        print(f"Python Discourse: cached ({int(time.time()-os.path.getmtime(CACHE))}s old)")
        return
    print("Python Discourse: fetching...")
    try:
        req = urllib.request.Request(URL, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = json.loads(resp.read())
        data["fetched_at"] = time.strftime("%Y-%m-%d %H:%M UTC", time.gmtime())
        with open(CACHE, "w") as f:
            json.dump(data, f)
        tl = data.get("topic_list", {}).get("topics", [])
        print(f"  topics: {len(tl)}")
        for t in tl[:6]:
            print(f"    - {t.get('title','')[:80]}")
    except Exception as e:
        print(f"  ERROR: {e}")

if __name__ == "__main__":
    force = "--force" in sys.argv
    sync(force)
