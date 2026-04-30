"""
Course Review API — Flask
POST /reviews          → submit a review for a course
GET  /reviews/<code>   → get all reviews for a course
GET  /courses          → list all courses (optional search by title/code)
GET  /courses/<code>   → get single course with reviews + avg rating
"""

from flask import Flask, request, jsonify
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timezone
import re
import os

app = Flask(__name__)

KEY_PATH = os.path.join(os.path.dirname(__file__), "../../nexus-stevens-firebase-adminsdk-fbsvc-afb5675f72.json")

if not firebase_admin._apps:
    cred = credentials.Certificate(KEY_PATH)
    firebase_admin.initialize_app(cred)

db = firestore.client()
COURSES_COL = "courses"


def make_doc_id(code: str, section: str = "") -> str:
    clean = re.sub(r"\s+", "", code.upper())
    return f"{clean}-{section.upper()}" if section else clean


def recompute_avg(reviews: list) -> float | None:
    rated = [r["rating"] for r in reviews if isinstance(r.get("rating"), (int, float))]
    return round(sum(rated) / len(rated), 2) if rated else None


# ── Submit a review ──────────────────────────────────────────────────────────

@app.route("/reviews", methods=["POST"])
def submit_review():
    data = request.get_json(silent=True) or {}

    course_code = (data.get("courseCode") or "").strip().upper()
    section = (data.get("section") or "").strip().upper()
    rating = data.get("rating")
    text = (data.get("text") or "").strip()
    is_anonymous = bool(data.get("isAnonymous", True))
    user_id = (data.get("userId") or "").strip()

    # Validate
    if not course_code:
        return jsonify({"error": "courseCode required"}), 400
    if rating is None or not (1 <= float(rating) <= 5):
        return jsonify({"error": "rating must be 1-5"}), 400
    if not text:
        return jsonify({"error": "review text required"}), 400

    doc_id = make_doc_id(course_code, section)
    ref = db.collection(COURSES_COL).document(doc_id)
    doc = ref.get()

    if not doc.exists:
        return jsonify({"error": f"Course {doc_id} not found"}), 404

    review = {
        "rating": float(rating),
        "text": text,
        "isAnonymous": is_anonymous,
        "userId": "" if is_anonymous else user_id,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }

    course_data = doc.to_dict()
    reviews = course_data.get("reviews") or []
    reviews.append(review)
    avg = recompute_avg(reviews)

    ref.update({"reviews": reviews, "avgRating": avg})

    return jsonify({"message": "Review submitted", "avgRating": avg}), 201


# ── Get reviews for a course ─────────────────────────────────────────────────

@app.route("/reviews/<path:course_id>", methods=["GET"])
def get_reviews(course_id: str):
    doc_id = re.sub(r"\s+", "", course_id.upper())
    ref = db.collection(COURSES_COL).document(doc_id)
    doc = ref.get()

    if not doc.exists:
        return jsonify({"error": "Course not found"}), 404

    data = doc.to_dict()
    return jsonify({
        "courseCode": data.get("courseCode"),
        "title": data.get("title"),
        "avgRating": data.get("avgRating"),
        "reviews": data.get("reviews") or [],
    })


# ── List / search courses ────────────────────────────────────────────────────

@app.route("/courses", methods=["GET"])
def list_courses():
    query = (request.args.get("q") or "").strip().lower()
    limit = min(int(request.args.get("limit", 50)), 200)

    docs = db.collection(COURSES_COL).limit(limit).stream()
    results = []

    for doc in docs:
        d = doc.to_dict()
        if query:
            if query not in d.get("title", "").lower() and query not in d.get("courseCode", "").lower():
                continue
        results.append({
            "id": doc.id,
            "courseCode": d.get("courseCode"),
            "section": d.get("section"),
            "title": d.get("title"),
            "professor": d.get("professor"),
            "day": d.get("day"),
            "time": d.get("time"),
            "location": d.get("location"),
            "avgRating": d.get("avgRating"),
            "reviewCount": len(d.get("reviews") or []),
        })

    return jsonify(results)


# ── Single course detail ─────────────────────────────────────────────────────

@app.route("/courses/<path:course_id>", methods=["GET"])
def get_course(course_id: str):
    doc_id = re.sub(r"\s+", "", course_id.upper())
    doc = db.collection(COURSES_COL).document(doc_id).get()

    if not doc.exists:
        return jsonify({"error": "Course not found"}), 404

    return jsonify(doc.to_dict())


if __name__ == "__main__":
    app.run(debug=True, port=5001)
