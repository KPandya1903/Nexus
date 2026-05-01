#!/usr/bin/env bash
# Deploy the Stevens Nexus FastAPI service to Cloud Run, then point
# Firebase Hosting at it via the rewrite in firebase.json.
#
# Prerequisites (one-time, per workstation):
#   1. `gcloud auth login` and `gcloud auth application-default login`
#   2. `firebase login`
#   3. Firebase project provisioned in console; ID set as "default" in
#      .firebaserc (currently the placeholder `stevens-nexus-prod`).
#   4. Required Google Cloud APIs enabled in the project:
#         cloudbuild.googleapis.com
#         run.googleapis.com
#         secretmanager.googleapis.com
#         artifactregistry.googleapis.com
#   5. ANTHROPIC_API_KEY stored in Secret Manager:
#         echo -n "sk-ant-..." | gcloud secrets create anthropic_api_key --data-file=-
#         gcloud secrets add-iam-policy-binding anthropic_api_key \
#             --member="serviceAccount:<COMPUTE_SA>" \
#             --role="roles/secretmanager.secretAccessor"
#      The deploy below mounts it as ANTHROPIC_API_KEY at runtime.
#
# Run from repo root:
#   bash scripts/deploy_firebase.sh
#
# Override defaults via env vars: PROJECT_ID, SERVICE_ID, REGION.

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-stevens-nexus-prod}"
SERVICE_ID="${SERVICE_ID:-stevens-nexus-api}"
REGION="${REGION:-us-central1}"

echo "==> 1/3  Building image (project=$PROJECT_ID, service=$SERVICE_ID)"
gcloud builds submit \
    --project "$PROJECT_ID" \
    --tag "gcr.io/$PROJECT_ID/$SERVICE_ID" \
    .

echo "==> 2/3  Deploying to Cloud Run (region=$REGION)"
gcloud run deploy "$SERVICE_ID" \
    --project "$PROJECT_ID" \
    --image "gcr.io/$PROJECT_ID/$SERVICE_ID" \
    --region "$REGION" \
    --platform managed \
    --allow-unauthenticated \
    --memory 1Gi \
    --cpu 1 \
    --timeout 600 \
    --concurrency 10 \
    --set-env-vars "FIREBASE_PROJECT_ID=$PROJECT_ID" \
    --update-secrets "ANTHROPIC_API_KEY=anthropic_api_key:latest"

echo "==> 3/3  Deploying Firebase Hosting rewrite"
firebase deploy --only hosting --project "$PROJECT_ID"

echo
echo "✓ Cloud Run service:        https://${SERVICE_ID}-${REGION}.run.app"
echo "✓ Firebase Hosting (front): https://${PROJECT_ID}.web.app"
echo
echo "Smoke test:"
echo "  curl https://${PROJECT_ID}.web.app/api/health  # once /api/health is implemented"
