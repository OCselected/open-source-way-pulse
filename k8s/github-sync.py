#!/usr/bin/env python3
"""
github-sync.py - Unified GitHub API fetcher for Project Pulse.
Fetches repo metadata (releases, commits, contributors) and caches as JSON.

Usage:
  github-sync.py sync [--project k8s|pytorch|vllm]
  github-sync.py status
  github-sync.py diff
"""

import json
import time
import os
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone, timedelta

TZ = timezone(timedelta(hours=8))
TODAY = datetime.now(TZ).strftime("%Y-%m-%d")

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PULSE_DIR = os.path.normpath(os.path.join(SCRIPT_DIR, ".."))
REGISTRY = os.path.join(SCRIPT_DIR, "registry.yaml")

# Project config: map project -> registry -> data dir
PROJECTS = {
    "k8s": {
        "reg": os.path.join(PULSE_DIR, "k8s", "registry.yaml"),
        "data": os.path.join(PULSE_DIR, "data", "github-k8s"),
        "api_root": "https://api.github.com/repos",
    },
    "pytorch": {
        "reg": os.path.join(PULSE_DIR, "pytorch", "registry.yaml"),
        "data": os.path.join(PULSE_DIR, "data", "github-pytorch"),
        "api_root": "https://api.github.com/repos",
    },
    "vllm": {
        "reg": os.path.join(PULSE_DIR, "vllm", "registry.yaml"),
        "data": os.path.join(PULSE_DIR, "data", "github-vllm"),
        "api_root": "https://api.github.com/repos",
    },
    "python": {
        "reg": os.path.join(PULSE_DIR, "python", "registry.yaml"),
        "data": os.path.join(PULSE_DIR, "data", "github-python"),
        "api_root": "https://api.github.com/repos",
    },
    "llvm": {
        "reg": os.path.join(PULSE_DIR, "llvm", "registry.yaml"),
        "data": os.path.join(PULSE_DIR, "data", "github-llvm"),
        "api_root": "https://api.github.com/repos",
    },
    "sglang": {
        "reg": os.path.join(PULSE_DIR, "sglang", "registry.yaml"),
        "data": os.path.join(PULSE_DIR, "data", "github-sglang"),
        "api_root": "https://api.github.com/repos",
    },
}

USER_AGENT = "Hermes-Pulse/1.0"
TIMEOUT = 15


def parse_registry(path):
    repos = []
    if not os.path.exists(path):
        return repos
    with open(path) as f:
        in_entry = False
        for line in f:
            s = line.strip()
            if s.startswith("- name:") or s.startswith("- repo:"):
                in_entry = True
            if in_entry and (s.startswith("repo:") or s.startswith("- repo:")):
                val = s.split(":", 1)[1].strip()
                val = val.strip('"').strip()
                if val and "http" not in val:
                    repos.append(val)
            # Exit entry on next top-level key or blank after entry
            if in_entry and s and not s.startswith("  ") and ":" in s and not s.startswith("#"):
                if not s.startswith("-"):
                    in_entry = False
    return repos


def github_api(path, max_time=15, retries=3):
    url = "https://api.github.com" + path if path.startswith("/") else "https://api.github.com" + path
    import subprocess as _sp
    _gh_token = ""
    try:
        _gh_token = _sp.run(["gh", "auth", "token"], capture_output=True, text=True, timeout=5).stdout.strip()
    except Exception:
        _gh_token = ""
    _gh_headers = {"User-Agent": USER_AGENT, "Accept": "application/vnd.github.v3+json"}
    if _gh_token:
        _gh_headers["Authorization"] = f"Bearer {_gh_token}"
    for attempt in range(retries):
        req = urllib.request.Request(url, headers=_gh_headers)
        try:
            with urllib.request.urlopen(req, timeout=max_time) as r:
                return json.loads(r.read().decode())
        except urllib.error.HTTPError as e:
            if e.code == 403:
                # Rate limited — honor Retry-After header or exponential backoff
                retry_after = int(e.headers.get("Retry-After", 2 ** attempt))
                time.sleep(retry_after)
                continue
            elif e.code in (429, 500, 502, 503):
                time.sleep(2 ** attempt)
                continue
            else:
                raise
        except (urllib.error.URLError, TimeoutError):
            time.sleep(2 ** attempt)
            continue
    return None


def fetch_repo(repo_slug, data_dir):
    """Fetch repo metadata and cache."""
    os.makedirs(data_dir, exist_ok=True)
    results = {"fetched_at": datetime.now(TZ).isoformat(), "repos": {}}

    try:
        repo = github_api("/repos/" + repo_slug)
    except Exception as e:
        return {"error": str(e), "repo": repo_slug}

    name = repo_slug.split("/")[-1]
    data = {
        "full_name": repo.get("full_name"),
        "stars": repo.get("stargazers_count"),
        "forks": repo.get("forks_count"),
        "open_issues": repo.get("open_issues_count"),
        "language": repo.get("language"),
        "description": repo.get("description"),
        "pushed_at": repo.get("pushed_at"),
        "created_at": repo.get("created_at"),
        "topics": repo.get("topics", []),
        "license": repo.get("license", {}).get("spdx_id") if repo.get("license") else None,
    }

    # Releases (last 5)
    try:
        rels = github_api("/repos/" + repo_slug + "/releases?per_page=5")
        data["releases"] = [
            {
                "tag": r.get("tag_name"),
                "name": r.get("name"),
                "published": r.get("published_at"),
                "prerelease": r.get("prerelease"),
            }
            for r in rels if isinstance(r, dict)
        ]
    except Exception as e:
        data["releases"] = []
        data["releases_error"] = str(e)

    # Commits last 7 days
    until = datetime.now(TZ).strftime("%Y-%m-%dT%H:%M:%SZ")
    since = (datetime.now(TZ) - timedelta(days=7)).strftime("%Y-%m-%dT%H:%M:%SZ")
    try:
        commits = github_api(
            "/repos/" + repo_slug + "/commits?per_page=100&until=" + until + "&since=" + since
        )
        data["commits_last_7d"] = len(commits) if isinstance(commits, list) else 0
        data["recent_commits"] = [
            {
                "sha": c.get("sha", "")[:12],
                "author": (c.get("commit", {}).get("author", {}).get("name", "?")),
                "date": c.get("commit", {}).get("author", {}).get("date", ""),
                "msg": c.get("commit", {}).get("message", "").split("\n")[0][:80],
            }
            for c in (commits[:20] if isinstance(commits, list) else [])
        ]
    except Exception as e:
        data["commits_last_7d"] = 0
        data["commits_error"] = str(e)

    # Contributors summary (last 30d, by org)
    try:
        stats = github_api("/repos/" + repo_slug + "/stats/commit_activity")
        data["commit_activity_52w"] = [w.get("total") for w in (stats[-52:] if isinstance(stats, list) else [])]
        data["commit_activity_avg_weekly"] = sum(data["commit_activity_52w"]) / max(len(data["commit_activity_52w"]), 1)
    except Exception:
        pass

    results["repos"][name] = data

    # Write cache
    outpath = os.path.join(data_dir, f"{name}-{TODAY}.json")
    with open(outpath, "w") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)

    # Update symlink
    link = os.path.join(data_dir, f"{name}-latest.json")
    os.system("ln -sf " + outpath + " " + link)

    return results


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else "sync"
    project = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2].startswith("--project=") else None

    if action == "sync":
        if project:
            projects = [project]
        else:
            projects = list(PROJECTS.keys())

        for p in projects:
            if p not in PROJECTS:
                print(f"Unknown project: {p}")
                continue
            cfg = PROJECTS[p]
            repos = parse_registry(cfg["reg"])
            if not repos:
                print(f"  {p}: no repos in registry")
                continue
            for repo in repos:
                print(f"  [{p}] syncing {repo}...")
                try:
                    res = fetch_repo(repo, cfg["data"])
                    if "error" in res:
                        print(f"    ERR: {res['error']}")
                    else:
                        repo_name = list(res.get("repos", {}).keys())[0]
                        stars = res["repos"][repo_name].get("stars", "?")
                        commits = res["repos"][repo_name].get("commits_last_7d", "?")
                        releases = len(res["repos"][repo_name].get("releases", []))
                        print(f"    OK: {repo_name} (stars={stars}, commits_7d={commits}, releases={releases})")
                except Exception as e:
                    print(f"    FAIL: {e}")
        print("sync complete.")
    elif action == "status":
        for p, cfg in PROJECTS.items():
            data_dir = cfg["data"]
            if not os.path.exists(data_dir):
                print(f"  [{p}] no data")
                continue
            for f in sorted(os.listdir(data_dir)):
                if f.endswith("-latest.json"):
                    fpath = os.path.join(data_dir, f)
                    mtime = datetime.fromtimestamp(os.path.getmtime(fpath), TZ).strftime("%m-%d %H:%M")
                    print(f"  [{p}] {f}: {mtime}")
    elif action == "diff":
        print("diff: show changes vs previous cache")
        for p, cfg in PROJECTS.items():
            data_dir = cfg["data"]
            if not os.path.exists(data_dir):
                continue
            files = sorted(f for f in os.listdir(data_dir) if f.endswith(".json") and "latest" not in f)
            if len(files) >= 2:
                prev = json.load(open(os.path.join(data_dir, files[-2])))
                curr = json.load(open(os.path.join(data_dir, files[-1])))
                prev_stars = list(prev.get("repos", {}).values())[0].get("stars", 0)
                curr_stars = list(curr.get("repos", {}).values())[0].get("stars", 0)
                print(f"  [{p}] stars: {prev_stars} -> {curr_stars} ({curr_stars - prev_stars:+d})")
    else:
        print("Usage: github-sync.py sync|status|diff")


if __name__ == "__main__":
    main()