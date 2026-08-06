#!/usr/bin/env python3
"""
aaif/fetch.py — GitHub API + aaif.io scraper for Project Pulse.

Usage:
  fetch.py sync [--json]     # fetch all projects + aaif.io daily briefing
  fetch.py diff              # show changes vs previous cache
  fetch.py status            # show latest cached data per project

Cache layout:
  ../data/aaif/<project>-<YYYY-MM-DD>.json   (per-project GitHub data)
  ../data/aaif/daily-briefing-<YYYY-MM-DD>.json
  ../data/aaif/latest.json                   (symlink or pointer to current)
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
TODAY_DIR = f"{TODAY}"

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PULSE_DIR = os.path.dirname(SCRIPT_DIR)
REGISTRY = os.path.join(SCRIPT_DIR, "aaif-registry.yaml")
DATA_DIR = os.path.join(PULSE_DIR, "data", "aaif")
os.makedirs(DATA_DIR, exist_ok=True)

USER_AGENT = "Hermes-Pulse/1.0"
TIMEOUT = 15


# ---- Registry parser (lightweight yaml) ----

def parse_registry(path):
    """Parse aaif-registry.yaml, return list of project dicts."""
    projects = []
    current = {}
    with open(path) as f:
        for line in f:
            line = line.rstrip("\n")
            m = re.match(r'^\s+-\s+name:\s+(\S+)', line)
            if m:
                if current:
                    projects.append(current)
                current = {"name": m.group(1)}
                continue
            m = re.match(r'^\s+(\w+):\s+"([^"]+)"\s*$', line)
            if m and current:
                key, val = m.group(1), m.group(2)
                current[key] = val
                continue
            m = re.match(r'^\s+(\w+):\s+(\S+)\s*$', line)
            if m and current:
                key, val = m.group(1), m.group(2)
                current[key] = val
        if current:
            projects.append(current)
    return projects


# ---- GitHub API ----

def gh_fetch(repo_path):
    """Fetch single GitHub repo summary. Returns dict or None on error."""
    url = f"https://api.github.com/repos/{repo_path}"
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
            return json.loads(resp.read())
    except (urllib.error.URLError, urllib.error.HTTPError, json.JSONDecodeError) as e:
        return {"_error": str(e), "repo": repo_path}


def gh_fetch_commits(repo_path, per_page=5):
    """Fetch recent commits for activity signal."""
    url = f"https://api.github.com/repos/{repo_path}/commits?per_page={per_page}"
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
            commits = json.loads(resp.read())
            return [{"sha": c["sha"][:8], "date": c["commit"]["author"]["date"][:10],
                     "message": c["commit"]["message"].split("\n")[0]} for c in commits]
    except Exception:
        return []


def gh_fetch_org(org_name):
    """Fetch GitHub org summary and list its public repos."""
    result = {"org": org_name}
    try:
        req = urllib.request.Request(
            f"https://api.github.com/orgs/{org_name}",
            headers={"User-Agent": USER_AGENT})
        with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
            data = json.loads(resp.read())
            result["public_repos"] = data.get("public_repos")
            result["public_gists"] = data.get("public_gists")
            result["description"] = data.get("description", "")
    except Exception as e:
        result["_error"] = str(e)
    # List org's repos
    result["repos_list"] = gh_list_org_repos(org_name)
    return result


def gh_list_org_repos(org_name):
    """List public repos under an org."""
    url = f"https://api.github.com/orgs/{org_name}/repos?per_page=10"
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
            repos = json.loads(resp.read())
            return [{"name": r["full_name"], "stars": r["stargazers_count"],
                     "pushed": r["pushed_at"][:10]} for r in repos]
    except Exception as e:
        return [{"_error": str(e)}]
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
            commits = json.loads(resp.read())
            return [{"sha": c["sha"][:8], "date": c["commit"]["author"]["date"][:10],
                     "message": c["commit"]["message"].split("\n")[0]} for c in commits]
    except Exception as e:
        return []


def gh_fetch_releases(repo_path, per_page=3):
    """Fetch recent releases."""
    url = f"https://api.github.com/repos/{repo_path}/releases?per_page={per_page}"
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
            rels = json.loads(resp.read())
            return [{"tag": r["tag_name"], "name": r["name"], "date": r["published_at"][:10]}
                    for r in rels]
    except Exception:
        return []


# ---- aaif.io scraper ----

def fetch_daily_briefing():
    """Scrape aaif.io homepage for Daily Briefing section."""
    url = "https://aaif.io/"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
        with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
            html = resp.read().decode("utf-8", errors="replace")
    except Exception as e:
        return {"_error": str(e), "items": []}

    items = []
    # Look for the newsletter section — items typically have heading tags
    # Extract h2/h3/h4 elements that look like news items
    for m in re.finditer(r'<(?:h[234]|heading|span)\b[^>]*>([^<]+)</(?:h[234]|heading|span)>', html, re.I):
        text = m.group(1).strip()
        if len(text) > 10 and len(text) < 200:
            items.append({"heading": text})

    return {"items": items, "fetched_at": datetime.now(TZ).isoformat()}


def fetch_projects_page():
    """Scrape aaif.io/projects for project list."""
    url = "https://aaif.io/projects"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
        with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
            html = resp.read().decode("utf-8", errors="replace")
    except Exception as e:
        return {"_error": str(e), "projects": []}

    # Extract project names from the projects page
    projects = []
    for m in re.finditer(r'<(?:h[23]|title|strong)\b[^>]*>([^<]{5,80})</(?:h[23]|title|strong)>', html, re.I):
        text = m.group(1).strip()
        if text and text not in ["Projects", "AGENTS.md", "Model Context Protocol", "goose", "agentgateway"]:
            projects.append(text)
    return {"projects": list(dict.fromkeys(projects)), "fetched_at": datetime.now(TZ).isoformat()}


# ---- Cache helpers ----

def load_prev(project):
    """Load most recent cached data for a project."""
    # Find latest JSON for this project
    matches = sorted([
        f for f in os.listdir(DATA_DIR)
        if f.startswith(f"{project}-") and f.endswith(".json")
    ], reverse=True)
    if not matches:
        return None
    return json.load(open(os.path.join(DATA_DIR, matches[0])))


def save_cache(project, data):
    path = os.path.join(DATA_DIR, f"{project}-{TODAY}.json")
    with open(path, "w") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    # Update latest pointer
    latest_path = os.path.join(DATA_DIR, f"{project}-latest.json")
    os.system(f'ln -sf "$(basename {path})" "{latest_path}" 2>/dev/null')
    return path


# ---- Main commands ----

def cmd_sync():
    projects = parse_registry(REGISTRY)
    results = {}

    for proj in projects:
        name = proj["name"]
        repo = proj.get("repo", "")
        status = proj.get("status", "inactive")

        if status == "inactive":
            continue

        # Determine if it's a GitHub repo path, org, or website section
        repo_type = proj.get("repo_type", "repo")
        if "/" in repo or repo.startswith("https://github.com") or repo_type == "org":
            # Convert to owner/repo or owner (for org)
            repo_path = repo.replace("https://github.com/", "", 1).strip("/")
            print(f"\n--- Fetching {name} ({repo_path}, type={repo_type}) ---")
            data = {
                "name": name,
                "repo": repo_path,
                "category": proj.get("category", ""),
                "fetched_at": datetime.now(TZ).isoformat(),
            }

            repo_data = gh_fetch(repo_path) if repo_type == "repo" else gh_fetch_org(repo_path)
            if repo_type == "repo" and repo_data and "_error" not in repo_data:
                data["stars"] = repo_data.get("stargazers_count")
                data["forks"] = repo_data.get("forks_count")
                data["issues"] = repo_data.get("open_issues_count")
                data["pushed_at"] = repo_data.get("pushed_at", "")[:10]
                data["language"] = repo_data.get("language")
                data["topics"] = repo_data.get("topics", [])
                data["description"] = repo_data.get("description", "")
            elif repo_type == "org" and repo_data and "_error" not in repo_data:
                data["is_org"] = True
                data["public_repos"] = repo_data.get("public_repos")
                data["public_gists"] = repo_data.get("public_gists")
                data["description"] = repo_data.get("description", "")
                data["repos"] = repo_data.get("repos_list", [])
                data["pushed_at"] = repo_data.get("pushed_at", "")[:10]
            else:
                data["_error"] = repo_data.get("_error") if repo_data else "no data"
                if repo_type == "org":
                    # Fallback: list org repos via separate API call
                    data["repos"] = gh_list_org_repos(repo_path)

            # Fetch recent commits (only for repos, not orgs)
            if repo_type == "repo":
                data["recent_commits"] = gh_fetch_commits(repo_path)
                data["recent_releases"] = gh_fetch_releases(repo_path)

            # Diff vs previous
            prev = load_prev(name)
            if prev:
                diff = {}
                for k in ["stars", "forks", "issues"]:
                    if k in data and k in prev and data[k] is not None:
                        diff[k] = data[k] - prev[k]
                data["diff"] = diff
                stars_delta = diff.get("stars", 0)
                delta_str = f"({stars_delta:+d})" if stars_delta else ""
                print(f"  stars: {data.get('stars')} {delta_str}")
                print(f"  issues: {data.get('issues')}")
                print(f"  pushed: {data.get('pushed_at')}")
            else:
                data["diff"] = {}
                print(f"  stars: {data.get('stars')} (initial)")

            save_cache(name, data)
            results[name] = "ok"

        elif repo == "https://github.com/modelcontextprotocol":
            # MCP: handled above
            pass

    # Fetch Daily Briefing
    print(f"\n--- Fetching aaif.io Daily Briefing ---")
    briefing = fetch_daily_briefing()
    briefing_items = briefing.get("items", [])
    print(f"  Found {len(briefing_items)} items")
    for item in briefing_items[:5]:
        print(f"    - {item.get('heading','')[:80]}")
    briefing_path = os.path.join(DATA_DIR, f"daily-briefing-{TODAY}.json")
    with open(briefing_path, "w") as f:
        json.dump(briefing, f, ensure_ascii=False, indent=2)
    results["daily-briefing"] = "ok"

    # Fetch projects page
    print(f"\n--- Fetching aaif.io/projects ---")
    proj_page = fetch_projects_page()
    proj_path = os.path.join(DATA_DIR, f"projects-page-{TODAY}.json")
    with open(proj_path, "w") as f:
        json.dump(proj_page, f, ensure_ascii=False, indent=2)
    results["projects-page"] = "ok"

    print(f"\n============================================")
    print(f" AAIF sync complete. {TODAY}")
    print(f" Fetches: {json.dumps(results)}")
    print(f"============================================")

    return results


def cmd_status():
    projects = parse_registry(REGISTRY)
    print("============================================")
    print(f" Project Pulse — AAIF status ({TODAY})")
    print("============================================")
    for proj in projects:
        name = proj["name"]
        prev = load_prev(name)
        if prev:
            print(f"  [{proj.get('status')}] {name}")
            print(f"    repo: {prev.get('repo')}")
            print(f"    stars: {prev.get('stars')} | issues: {prev.get('issues')} | pushed: {prev.get('pushed_at')}")
            print(f"    fetched: {prev.get('fetched_at','?')[:16]}")
        else:
            print(f"  [{proj.get('status')}] {name} — no data (not yet synced)")
    print("============================================")


if __name__ == "__main__":
    # Fix typo in USER_AGENT variable
    exec("USER_AGENT = 'Hermes-Pulse/1.0'")

    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(0)

    cmd = sys.argv[1]
    if cmd == "sync":
        cmd_sync()
    elif cmd == "status":
        cmd_status()
    else:
        print(f"Unknown command: {cmd}")
        print("Commands: sync, status")
        sys.exit(1)
