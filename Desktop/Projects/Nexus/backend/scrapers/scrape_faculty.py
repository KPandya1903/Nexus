"""
Stevens faculty scraper — CS & Engineering departments.
Reads __NEXT_DATA__ JSON from each profile page.
Outputs: faculty.json
"""

import json
import re
import time
import requests
from bs4 import BeautifulSoup

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
}

DEPARTMENT_URLS = [
    ("CS", "https://www.stevens.edu/school-engineering-science/departments/computer-science/faculty"),
    ("Engineering", "https://www.stevens.edu/school-engineering-science/departments/electrical-computer-engineering/faculty"),
]

BASE_URL = "https://www.stevens.edu"


def get_next_data(html: str) -> dict:
    soup = BeautifulSoup(html, "html.parser")
    tag = soup.find("script", {"id": "__NEXT_DATA__"})
    return json.loads(tag.string) if tag else {}


def get_faculty_slugs(dept_url: str) -> list[str]:
    r = requests.get(dept_url, headers=HEADERS, timeout=15)
    r.raise_for_status()

    slugs = []

    # Try NEXT_DATA first
    data = get_next_data(r.text)
    if data:
        try:
            items = data["props"]["pageProps"]["pageData"]["facultyCollection"]["items"]
            for item in items:
                slug = item.get("slug")
                if slug:
                    slugs.append(slug)
        except (KeyError, TypeError):
            pass

    # Fallback: parse /profile/ links from HTML
    if not slugs:
        soup = BeautifulSoup(r.text, "html.parser")
        for a in soup.find_all("a", href=re.compile(r"^/profile/")):
            slug = a["href"].replace("/profile/", "").strip("/")
            if slug and slug not in slugs:
                slugs.append(slug)

    return slugs


def strip_html(text: str) -> str:
    return BeautifulSoup(text, "html.parser").get_text(separator=" ", strip=True)


def parse_section(item: dict) -> str:
    """Flatten a sectionsCollection item into a readable string."""
    obj = item.get("object")
    if not obj:
        return ""

    if isinstance(obj, dict):
        return strip_html(obj.get("value", ""))

    if isinstance(obj, list):
        parts = []
        for entry in obj:
            # Education
            if "deg" in entry:
                parts.append(
                    f"{entry.get('deg','')} in {entry.get('major','')} — {entry.get('school','')} ({entry.get('dty_comp','')})"
                )
            # Service / societies
            elif "org" in entry:
                role = entry.get("title") or entry.get("member_type") or entry.get("status", "")
                parts.append(f"{role}: {entry.get('org','')}")
            else:
                parts.append(str(entry))
        return "\n".join(parts)

    return ""


def scrape_profile(slug: str, dept_label: str) -> dict | None:
    url = f"{BASE_URL}/profile/{slug}"
    try:
        r = requests.get(url, headers=HEADERS, timeout=15)
        r.raise_for_status()
    except requests.RequestException as e:
        print(f"  SKIP {slug}: {e}")
        return None

    data = get_next_data(r.text)
    if not data:
        print(f"  SKIP {slug}: no NEXT_DATA")
        return None

    try:
        pd = data["props"]["pageProps"]["pageData"]
    except KeyError:
        print(f"  SKIP {slug}: unexpected NEXT_DATA shape")
        return None

    profile: dict = {
        "slug": slug,
        "profile_url": url,
        "department_label": dept_label,
        "name": pd.get("title", ""),
        "rank": "",
        "email": pd.get("email", ""),
        "phone": pd.get("phone", ""),
        "website": pd.get("website", ""),
        "photo_url": "",
        "department": "",
        "research_interests": "",
        "bio": "",
        "education": "",
        "experience": "",
        "active_projects": "",
        "publications": "",
        "courses": "",
        "honors": "",
        "professional_societies": "",
    }

    # Photo
    img = pd.get("image") or {}
    inner = img.get("image") or {}
    profile["photo_url"] = inner.get("url", "")

    # Department from positionsCollection
    try:
        positions = pd["positionsCollection"]["items"]
        depts = [
            p["department"]["title"]
            for p in positions
            if p.get("department", {}).get("showOnProfile")
        ]
        profile["department"] = ", ".join(depts)
    except (KeyError, TypeError):
        pass

    # Sections
    section_key_map = {
        "research": "research_interests",
        "general information": "bio",
        "education": "education",
        "experience": "experience",
        "grants, contracts and funds": "active_projects",
        "selected publications": "publications",
        "courses": "courses",
        "honors and awards": "honors",
        "professional societies": "professional_societies",
        "appointments": "_appointments",
    }

    try:
        sections = pd["sectionsCollection"]["items"]
    except (KeyError, TypeError):
        sections = []

    for item in sections:
        title = (item.get("title") or "").lower()
        field = next((v for k, v in section_key_map.items() if k in title), None)
        if field == "_appointments":
            # Extract rank from e.g. "Stevens Institute of Technology, Assistant Professor, 2021 - present"
            appt_text = parse_section(item)
            import re as _re
            ranks = ["Professor", "Lecturer", "Instructor", "Scientist", "Researcher"]
            for rank in ranks:
                m = _re.search(rf"([\w\s]*{rank}[\w\s]*),", appt_text)
                if m:
                    profile["rank"] = m.group(1).strip()
                    break
            if not profile["rank"]:
                profile["rank"] = appt_text.split(",")[1].strip() if "," in appt_text else appt_text
        elif field:
            profile[field] = parse_section(item)

    return profile


def main():
    all_faculty: list[dict] = []
    seen: set[str] = set()

    for dept_label, dept_url in DEPARTMENT_URLS:
        print(f"\n[{dept_label}] {dept_url}")
        slugs = get_faculty_slugs(dept_url)
        print(f"  {len(slugs)} profiles found")

        for slug in slugs:
            if slug in seen:
                continue
            seen.add(slug)
            print(f"  scraping {slug} ...")
            profile = scrape_profile(slug, dept_label)
            if profile:
                all_faculty.append(profile)
            time.sleep(0.5)

    with open("faculty.json", "w") as f:
        json.dump(all_faculty, f, indent=2, ensure_ascii=False)

    print(f"\nDone — {len(all_faculty)} profiles → faculty.json")


if __name__ == "__main__":
    main()
