# Stevens Nexus FastAPI service — Cloud Run container.
#
# Target: Google Cloud Run, fronted by Firebase Hosting (firebase.json rewrites
# all paths to the `stevens-nexus-api` service in us-central1).
#
# Cloud Run injects the PORT env var at runtime; uvicorn binds to it. The
# default fallback (8080) matches Cloud Run's documented contract.

FROM python:3.11-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Dependencies first — leverages Docker layer caching when only application
# code changes.
COPY api/lease_pipeline/requirements.txt /app/api/lease_pipeline/requirements.txt
RUN pip install -r /app/api/lease_pipeline/requirements.txt \
    && pip install "fastapi>=0.110" "uvicorn[standard]>=0.30" "python-multipart>=0.0.9"

# Application code + data + prompts.
COPY api /app/api
COPY data /app/data
COPY prompts /app/prompts

ENV PORT=8080
EXPOSE 8080

# api/main.py is NOT YET implemented (per Claude.md build status). Once Kunj
# adds the FastAPI app entry point, this CMD will start the service. Until
# then, the deploy will fail loud at runtime with a clear ImportError —
# preferable to a silent stub.
CMD ["sh", "-c", "uvicorn api.main:app --host 0.0.0.0 --port ${PORT:-8080}"]
