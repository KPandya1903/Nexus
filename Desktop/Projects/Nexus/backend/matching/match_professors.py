"""
Semantic professor matching using sentence-transformers.
Embeds faculty research profiles once, caches to disk.
Given a student interest string, returns top N matches with scores and reasoning.
"""

import json
import os
import pickle
import numpy as np
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity

MODEL_NAME = "all-MiniLM-L6-v2"
FACULTY_JSON = "../scrapers/faculty.json"
CACHE_FILE = "faculty_embeddings.pkl"


def build_faculty_text(prof: dict) -> str:
    """Combine relevant fields into one rich text blob for embedding."""
    parts = [
        prof.get("name", ""),
        prof.get("research_interests", ""),
        prof.get("bio", ""),
        prof.get("active_projects", ""),
        prof.get("publications", "")[:500],  # cap publications length
    ]
    return " ".join(p for p in parts if p).strip()


def load_faculty() -> list[dict]:
    with open(FACULTY_JSON) as f:
        return json.load(f)


def get_embeddings(faculty: list[dict], model: SentenceTransformer) -> np.ndarray:
    """Load cached embeddings or compute and cache them."""
    if os.path.exists(CACHE_FILE):
        print("Loading cached embeddings...")
        with open(CACHE_FILE, "rb") as f:
            return pickle.load(f)

    print("Computing faculty embeddings (first run, takes ~30s)...")
    texts = [build_faculty_text(p) for p in faculty]
    embeddings = model.encode(texts, show_progress_bar=True, normalize_embeddings=True)

    with open(CACHE_FILE, "wb") as f:
        pickle.dump(embeddings, f)

    print("Embeddings cached to", CACHE_FILE)
    return embeddings


def match(student_input: str, top_n: int = 3) -> list[dict]:
    """
    Match a student interest string against all faculty.
    Returns top_n professors with score and reasoning.
    """
    model = SentenceTransformer(MODEL_NAME)
    faculty = load_faculty()
    faculty_embeddings = get_embeddings(faculty, model)

    student_embedding = model.encode([student_input], normalize_embeddings=True)
    scores = cosine_similarity(student_embedding, faculty_embeddings)[0]

    top_indices = np.argsort(scores)[::-1][:top_n]

    results = []
    for idx in top_indices:
        prof = faculty[idx]
        score = float(scores[idx])

        # Build reasoning from matched fields
        research = prof.get("research_interests", "").strip()
        projects = prof.get("active_projects", "").strip()
        reasoning_parts = []
        if research:
            reasoning_parts.append(f"Research: {research}")
        if projects:
            reasoning_parts.append(f"Active projects: {projects}")

        results.append({
            "name": prof.get("name"),
            "title": prof.get("rank"),
            "department": prof.get("department"),
            "email": prof.get("email"),
            "photo_url": prof.get("photo_url"),
            "profile_url": prof.get("profile_url"),
            "research_interests": research,
            "active_projects": projects,
            "match_score": round(score, 4),
            "reasoning": " | ".join(reasoning_parts) if reasoning_parts else "General alignment with your interests.",
        })

    return results


def main():
    print("=== Stevens Professor Matcher ===\n")
    student_input = input("Enter your research interests: ").strip()
    if not student_input:
        print("No input provided.")
        return

    print(f"\nFinding top 3 matches for: '{student_input}'\n")
    matches = match(student_input)

    for i, m in enumerate(matches, 1):
        print(f"#{i} {m['name']} — {m['title']}")
        print(f"   Score:    {m['match_score']}")
        print(f"   Research: {m['research_interests']}")
        print(f"   Projects: {m['active_projects']}")
        print(f"   Email:    {m['email']}")
        print()


if __name__ == "__main__":
    main()
