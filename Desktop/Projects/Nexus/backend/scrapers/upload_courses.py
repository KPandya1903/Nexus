"""
Upload courses.json to Firestore `courses` collection.
Document ID = courseCode + section (e.g. "CS115-A") for easy querying.
"""

import json
import re
import firebase_admin
from firebase_admin import credentials, firestore

KEY_PATH = "../../nexus-stevens-firebase-adminsdk-fbsvc-afb5675f72.json"
COURSES_JSON = "courses.json"
COLLECTION = "courses"


def make_doc_id(course: dict) -> str:
    code = re.sub(r"\s+", "", course["courseCode"])  # "CS 115" → "CS115"
    section = course["section"]
    return f"{code}-{section}"


def main():
    cred = credentials.Certificate(KEY_PATH)
    if not firebase_admin._apps:
        firebase_admin.initialize_app(cred)
    db = firestore.client()

    with open(COURSES_JSON) as f:
        courses = json.load(f)

    print(f"Uploading {len(courses)} course sections to Firestore...")

    batch = db.batch()
    count = 0

    for course in courses:
        doc_id = make_doc_id(course)
        ref = db.collection(COLLECTION).document(doc_id)
        batch.set(ref, course)
        count += 1

        # Firestore batch limit is 500
        if count % 500 == 0:
            batch.commit()
            batch = db.batch()
            print(f"  Committed {count} documents...")

    batch.commit()
    print(f"\nDone — {count} course sections written to '{COLLECTION}' collection.")


if __name__ == "__main__":
    main()
