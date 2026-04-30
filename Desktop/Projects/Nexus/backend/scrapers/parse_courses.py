"""
Parse courses.txt into structured JSON.
Each 4-line block:
  Line 1: CODE-SECTION - Title
  Line 2: Title | Status | Professor (optional)
  Line 3: "Section Details"
  Line 4: Location | Day | Time  (or "(empty)")
Outputs: courses.json
"""

import json
import re

INPUT = "../../courses.txt"
OUTPUT = "courses.json"


def parse():
    with open(INPUT, encoding="utf-8") as f:
        lines = [l.rstrip("\n") for l in f.readlines()]

    courses = []
    i = 0

    while i < len(lines):
        line = lines[i].strip()

        # Match course header: e.g. "CS 115-A - Introduction to Computer Science"
        m = re.match(r"^([A-Z]{2,4}\s+\d{3,4}[A-Z0-9]*)-([A-Z0-9\-]+)\s+-\s+(.+)$", line)
        if not m:
            i += 1
            continue

        course_code = m.group(1).strip()   # e.g. "CS 115"
        section = m.group(2).strip()        # e.g. "A"
        title = m.group(3).strip()

        # Line 2: Title | Status | Professor
        professor = ""
        status = ""
        if i + 1 < len(lines):
            parts = [p.strip() for p in lines[i + 1].split("|")]
            if len(parts) >= 2:
                status = parts[1] if len(parts) > 1 else ""
                professor = parts[2] if len(parts) > 2 else ""

        # Line 3: "Section Details" — skip
        # Line 4: Location | Day | Time
        location = ""
        day = ""
        time_slot = ""
        if i + 3 < len(lines):
            detail = lines[i + 3].strip()
            if detail and detail != "(empty)":
                detail_parts = [p.strip() for p in detail.split("|")]
                location = detail_parts[0] if len(detail_parts) > 0 else ""
                day = detail_parts[1] if len(detail_parts) > 1 else ""
                time_slot = detail_parts[2] if len(detail_parts) > 2 else ""

        courses.append({
            "courseCode": course_code,
            "section": section,
            "title": title,
            "professor": professor,
            "status": status,
            "location": location,
            "day": day,
            "time": time_slot,
            "reviews": [],  # populated later via app
            "avgRating": None,
        })

        i += 4  # advance past 4-line block

    return courses


def main():
    courses = parse()
    with open(OUTPUT, "w") as f:
        json.dump(courses, f, indent=2, ensure_ascii=False)
    print(f"Parsed {len(courses)} course sections → {OUTPUT}")

    # Quick stats
    unique_codes = len(set(c["courseCode"] for c in courses))
    print(f"Unique course codes: {unique_codes}")


if __name__ == "__main__":
    main()
