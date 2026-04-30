"""
GitHub → Gemini → Professor Matcher pipeline.
1. Load scraped GitHub profile (or scrape fresh)
2. Try Gemini to extract research themes; fall back to local TF-IDF
3. Feed themes into semantic professor matcher
4. Return top 3 professor matches with reasoning
"""

import json
import os
import sys
sys.path.append("../scrapers")

from dotenv import load_dotenv
from match_professors import match

load_dotenv(dotenv_path="../../.env")

_gemini_client = None

def _get_gemini():
    global _gemini_client
    if _gemini_client is None:
        try:
            from google import genai
            key = os.environ.get("GEMINI_API_KEY", "")
            if key:
                _gemini_client = genai.Client(api_key=key)
        except Exception:
            pass
    return _gemini_client


def extract_themes_local(github_profile: dict) -> str:
    """Local fallback: TF-IDF keyword extraction from repo text."""
    from sklearn.feature_extraction.text import TfidfVectorizer

    summaries = github_profile.get("repo_summaries", [])
    topics = github_profile.get("topics", [])
    languages = github_profile.get("top_languages", [])

    corpus = summaries + topics
    if not corpus:
        return " ".join(languages)

    vectorizer = TfidfVectorizer(
        stop_words="english",
        max_features=30,
        ngram_range=(1, 2),
    )
    try:
        vectorizer.fit_transform(corpus)
        keywords = vectorizer.get_feature_names_out().tolist()
    except Exception:
        keywords = topics

    themes = ", ".join(keywords[:15] + languages[:5])
    print(f"\n[Local] Extracted themes:\n  {themes}\n")
    return themes


def extract_themes(github_profile: dict) -> str:
    """Try Gemini first, fall back to local TF-IDF if quota exceeded or unavailable."""
    client = _get_gemini()

    if client:
        username = github_profile.get("username", "")
        languages = ", ".join(github_profile.get("top_languages", []))
        topics = ", ".join(github_profile.get("topics", []))
        summaries = github_profile.get("repo_summaries", [])
        repo_text = "\n".join(f"- {s}" for s in summaries[:15])

        prompt = f"""You are analyzing a student's GitHub profile to identify their academic research interests.

GitHub Username: {username}
Top Programming Languages: {languages}
Repository Topics: {topics}

Repository Descriptions & README Snippets:
{repo_text}

Based on this GitHub activity, identify 5-8 specific academic research themes or fields this student is interested in or working on.
Focus on: AI/ML subfields, systems topics, security areas, mathematical foundations, application domains, etc.
Be specific — not just "machine learning" but "reinforcement learning for robotics" or "NLP for low-resource languages".

Respond with ONLY a comma-separated list of research themes. No explanation, no numbering, no extra text."""

        try:
            response = client.models.generate_content(
                model="gemini-2.0-flash-lite",
                contents=prompt,
            )
            themes = response.text.strip()
            print(f"\n[Gemini] Extracted themes:\n  {themes}\n")
            return themes
        except Exception as e:
            print(f"[Gemini] Failed ({e.__class__.__name__}), using local extraction...")

    return extract_themes_local(github_profile)


def run_pipeline(github_json_path: str = None, username: str = None) -> list[dict]:
    if github_json_path:
        with open(github_json_path) as f:
            github_profile = json.load(f)
    elif username:
        from scrape_github import scrape
        github_profile = scrape(username)
    else:
        username = input("Enter GitHub username: ").strip()
        from scrape_github import scrape
        github_profile = scrape(username)

    print(f"Analyzing @{github_profile['username']}'s GitHub profile...")

    themes = extract_themes(github_profile)

    print("Matching against Stevens faculty...")
    matches = match(themes, top_n=3)

    print(f"\n=== Top Professor Matches for @{github_profile['username']} ===\n")
    for i, m in enumerate(matches, 1):
        print(f"#{i} {m['name']} — {m['title']}")
        print(f"   Score:    {m['match_score']}")
        print(f"   Research: {m['research_interests']}")
        print(f"   Projects: {m['active_projects']}")
        print(f"   Email:    {m['email']}")
        print()

    result = {
        "github_username": github_profile["username"],
        "extracted_themes": themes,
        "matches": matches,
    }

    out_file = f"{github_profile['username']}_matches.json"
    with open(out_file, "w") as f:
        json.dump(result, f, indent=2)
    print(f"Saved to {out_file}")

    return matches


if __name__ == "__main__":
    if len(sys.argv) > 1:
        run_pipeline(github_json_path=sys.argv[1])
    else:
        run_pipeline()
