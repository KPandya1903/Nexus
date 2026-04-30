"""
GitHub profile scraper — pulls public repos, languages, topics, descriptions.
Builds a rich interest string for professor matching.
"""

import json
import requests
import sys

BASE = "https://api.github.com"
HEADERS = {"Accept": "application/vnd.github+json"}


def get_repos(username: str) -> list[dict]:
    repos = []
    page = 1
    while True:
        r = requests.get(
            f"{BASE}/users/{username}/repos",
            headers=HEADERS,
            params={"per_page": 100, "page": page, "type": "public"},
            timeout=15,
        )
        if r.status_code == 404:
            print(f"User '{username}' not found.")
            sys.exit(1)
        r.raise_for_status()
        batch = r.json()
        if not batch:
            break
        repos.extend(batch)
        page += 1
    return repos


def get_readme(username: str, repo: str) -> str:
    r = requests.get(
        f"{BASE}/repos/{username}/{repo}/readme",
        headers={**HEADERS, "Accept": "application/vnd.github.raw"},
        timeout=10,
    )
    if r.status_code == 200:
        import re
        text = r.text
        # Strip HTML tags and markdown artifacts
        text = re.sub(r"<[^>]+>", " ", text)
        text = re.sub(r"[#*`<>|\\]", " ", text)
        text = re.sub(r"&\w+;", " ", text)       # HTML entities like &nbsp;
        text = re.sub(r"https?://\S+", "", text)  # URLs
        text = re.sub(r"\s+", " ", text).strip()
        return text[:400]
    return ""


def get_languages(username: str, repo: str) -> list[str]:
    r = requests.get(
        f"{BASE}/repos/{username}/{repo}/languages",
        headers=HEADERS,
        timeout=10,
    )
    if r.status_code == 200:
        return list(r.json().keys())
    return []


def scrape(username: str) -> dict:
    print(f"Fetching repos for @{username}...")
    repos = get_repos(username)
    print(f"  {len(repos)} public repos found")

    all_languages: dict[str, int] = {}
    all_topics: list[str] = []
    repo_summaries: list[str] = []

    for repo in repos:
        name = repo["name"]
        desc = repo.get("description") or ""
        topics = repo.get("topics") or []
        stars = repo.get("stargazers_count", 0)
        fork = repo.get("fork", False)

        # Skip forks — not the user's own work
        if fork:
            continue

        print(f"  processing {name}...")

        # Languages
        langs = get_languages(username, name)
        for lang in langs:
            all_languages[lang] = all_languages.get(lang, 0) + 1

        # Topics
        all_topics.extend(topics)

        # README snippet for non-trivial repos
        readme = ""
        if stars > 0 or desc:
            readme = get_readme(username, name)

        summary_parts = [name.replace("-", " ").replace("_", " ")]
        if desc:
            summary_parts.append(desc)
        if readme:
            summary_parts.append(readme)

        repo_summaries.append(" ".join(summary_parts))

    # Sort languages by frequency
    sorted_langs = sorted(all_languages.items(), key=lambda x: x[1], reverse=True)
    top_langs = [l for l, _ in sorted_langs[:10]]

    # Deduplicate topics
    unique_topics = list(dict.fromkeys(all_topics))

    # Build interest string for matcher
    interest_string = " ".join([
        " ".join(top_langs),
        " ".join(unique_topics),
        " ".join(repo_summaries[:20]),  # cap to 20 repos
    ]).strip()

    profile = {
        "username": username,
        "total_repos": len(repos),
        "top_languages": top_langs,
        "topics": unique_topics,
        "repo_summaries": repo_summaries,
        "interest_string": interest_string,
    }

    return profile


def main():
    username = input("Enter GitHub username: ").strip()
    if not username:
        print("No username provided.")
        return

    profile = scrape(username)

    out_file = f"{username}_github.json"
    with open(out_file, "w") as f:
        json.dump(profile, f, indent=2)

    print(f"\n=== GitHub Profile: @{username} ===")
    print(f"Repos:     {profile['total_repos']}")
    print(f"Languages: {', '.join(profile['top_languages'])}")
    print(f"Topics:    {', '.join(profile['topics'][:10])}")
    print(f"\nInterest string preview:")
    print(profile["interest_string"][:300])
    print(f"\nSaved to {out_file}")

    return profile


if __name__ == "__main__":
    main()
