"""
In-house email draft generator.
Uses professor research data + student GitHub profile to generate
3 personalized cold outreach email variations.
No external API needed.
"""

import json
import random


# ── Templates ─────────────────────────────────────────────────────────────────

TEMPLATES = {
    "formal": """\
Subject: Research Inquiry — {research_area}

Dear Professor {last_name},

I am {student_name}, a student at Stevens Institute of Technology. I came across your work on {research_area} and found it closely aligned with my academic interests.

{personal_connection}

I have been working on {student_skills} through various projects, including {top_project}. I believe your research on {specific_research} presents an exciting opportunity for me to contribute meaningfully.

{project_hook}

I would greatly appreciate the opportunity to discuss potential research involvement or any available positions in your group. I am happy to meet at your convenience.

Thank you for your time and consideration.

Sincerely,
{student_name}
Stevens Institute of Technology
{student_email}
""",

    "research_focused": """\
Subject: Interest in Your {research_area} Research

Dear Professor {last_name},

My name is {student_name}, and I am a student at Stevens Institute of Technology deeply interested in {research_area}.

{personal_connection}

{project_hook}

My technical background includes {student_skills}, which I have applied in projects such as {top_project}. I am particularly drawn to {specific_research} and would love to explore how I could contribute to your ongoing work.

Would you be open to a brief meeting or email exchange to discuss possible research opportunities?

Best regards,
{student_name}
{student_email}
""",

    "concise": """\
Subject: Research Opportunity Inquiry — {student_name}

Hi Professor {last_name},

I'm {student_name}, a Stevens student interested in {research_area}. Your work on {specific_research} stood out to me because {personal_connection_short}

I've built projects using {student_skills} — most recently {top_project} — and I'm eager to apply these skills in a research setting.

{project_hook}

Would you have 15 minutes to chat about research opportunities in your group?

Thanks,
{student_name}
{student_email}
""",
}


# ── Helpers ───────────────────────────────────────────────────────────────────

def first_sentence(text: str) -> str:
    if not text:
        return ""
    sentences = text.replace("\n", " ").split(".")
    return sentences[0].strip() + "." if sentences else text[:120]


def extract_research_area(research_interests: str) -> str:
    if not research_interests:
        return "your research area"
    # Take first topic before comma
    area = research_interests.split(",")[0].strip()
    return area[:80] if area else "your research area"


def extract_specific_research(research_interests: str, active_projects: str) -> str:
    if active_projects and len(active_projects) > 10:
        return first_sentence(active_projects)
    if research_interests:
        parts = research_interests.split(",")
        return parts[1].strip() if len(parts) > 1 else parts[0].strip()
    return "your recent projects"


def build_personal_connection(research_interests: str, student_themes: list[str]) -> str:
    if not research_interests or not student_themes:
        return "Your research focus aligns closely with my academic and project experience."

    research_lower = research_interests.lower()
    matched = [t for t in student_themes if any(word in research_lower for word in t.lower().split())]

    if matched:
        return f"Your work on {extract_research_area(research_interests)} directly connects with my experience in {', '.join(matched[:2])}."
    return f"Your focus on {extract_research_area(research_interests)} aligns with the direction I want to take my studies."


def build_project_hook(active_projects: str) -> str:
    if not active_projects or len(active_projects) < 10:
        return "I am eager to contribute to your lab's research agenda."
    project = first_sentence(active_projects)
    return f"I was particularly excited to learn about your project: {project} I believe I could add value to this effort."


def format_skills(languages: list[str], themes: list[str]) -> str:
    parts = []
    if languages:
        parts.append(", ".join(languages[:4]))
    if themes:
        clean = [t for t in themes[:3] if len(t.split()) <= 3]
        if clean:
            parts.append(", ".join(clean))
    return " and ".join(parts) if parts else "various technologies"


def top_project(repo_summaries: list[str]) -> str:
    if not repo_summaries:
        return "my personal projects"
    # Pick the most descriptive summary
    best = max(repo_summaries, key=lambda s: len(s))
    return best[:100].strip()


# ── Main Generator ────────────────────────────────────────────────────────────

def generate_emails(
    professor: dict,
    student_name: str,
    student_email: str,
    github_profile: dict = None,
    student_themes: list[str] = None,
) -> dict[str, str]:
    """
    Generate 3 email variations for a student → professor outreach.

    Args:
        professor: dict from faculty.json / Firestore
        student_name: full name
        student_email: @stevens.edu email
        github_profile: output from scrape_github.py (optional)
        student_themes: list of extracted interest keywords (optional)

    Returns:
        dict with keys "formal", "research_focused", "concise"
    """

    research_interests = professor.get("research_interests") or ""
    active_projects = professor.get("active_projects") or ""
    prof_name = professor.get("name") or "Professor"
    last_name = prof_name.split()[-1] if prof_name else "Professor"

    languages = []
    repo_summaries = []
    if github_profile:
        languages = github_profile.get("top_languages") or []
        repo_summaries = github_profile.get("repo_summaries") or []

    themes = student_themes or []

    variables = {
        "student_name": student_name,
        "student_email": student_email,
        "last_name": last_name,
        "research_area": extract_research_area(research_interests),
        "specific_research": extract_specific_research(research_interests, active_projects),
        "personal_connection": build_personal_connection(research_interests, themes),
        "personal_connection_short": build_personal_connection(research_interests, themes),
        "project_hook": build_project_hook(active_projects),
        "student_skills": format_skills(languages, themes),
        "top_project": top_project(repo_summaries),
    }

    return {
        style: template.format(**variables)
        for style, template in TEMPLATES.items()
    }


# ── CLI ───────────────────────────────────────────────────────────────────────

def main():
    import os, sys
    sys.path.append("../scrapers")

    # Load faculty
    faculty_path = "../scrapers/faculty.json"
    with open(faculty_path) as f:
        faculty = json.load(f)

    print("=== Stevens Email Draft Generator ===\n")
    student_name = input("Your full name: ").strip()
    student_email = input("Your Stevens email: ").strip()

    # Optional GitHub profile
    github_profile = None
    student_themes = []
    github_path = input("GitHub JSON path (press Enter to skip): ").strip()
    if github_path and os.path.exists(github_path):
        with open(github_path) as f:
            github_profile = json.load(f)
        student_themes = github_profile.get("interest_string", "").split(", ")

    # Pick professor
    query = input("Professor last name or keyword: ").strip().lower()
    matches = [p for p in faculty if query in (p.get("name") or "").lower()]

    if not matches:
        print("No professor found.")
        return

    professor = matches[0]
    print(f"\nGenerating emails for: {professor['name']}\n")

    emails = generate_emails(
        professor=professor,
        student_name=student_name,
        student_email=student_email,
        github_profile=github_profile,
        student_themes=student_themes,
    )

    for style, body in emails.items():
        print(f"\n{'='*60}")
        print(f"[{style.upper()}]")
        print('='*60)
        print(body)

    # Save
    out = {
        "professor": professor["name"],
        "student": student_name,
        "emails": emails,
    }
    out_file = f"email_drafts_{professor['slug']}.json"
    with open(out_file, "w") as f:
        json.dump(out, f, indent=2)
    print(f"\nSaved to {out_file}")


if __name__ == "__main__":
    main()
