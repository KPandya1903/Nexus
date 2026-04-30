"""
Upload faculty.json to Firestore `faculty` collection.
Run once to seed the database.
"""

import json
import firebase_admin
from firebase_admin import credentials, firestore

KEY_PATH = "../../nexus-stevens-firebase-adminsdk-fbsvc-afb5675f72.json"
FACULTY_JSON = "faculty.json"
COLLECTION = "faculty"

cred = credentials.Certificate(KEY_PATH)
firebase_admin.initialize_app(cred)
db = firestore.client()

with open(FACULTY_JSON) as f:
    faculty = json.load(f)

print(f"Uploading {len(faculty)} faculty profiles to Firestore...")

for prof in faculty:
    slug = prof.get("slug")
    if not slug:
        continue
    db.collection(COLLECTION).document(slug).set(prof)
    print(f"  ✓ {prof.get('name')} ({slug})")

print(f"\nDone — {len(faculty)} documents written to '{COLLECTION}' collection.")
