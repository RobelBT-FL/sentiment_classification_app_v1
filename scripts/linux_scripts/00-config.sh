#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# 00-config.sh — EDIT THIS FILE ONCE. All other scripts source it.
# ═══════════════════════════════════════════════════════════════════════════════
# Run: source 00-config.sh   (don't execute directly — source it)

# ── Azure Identity ─────────────────────────────────────────────────────────────
export AZURE_SUBSCRIPTION_ID="54ba9555-5ee7-47a1-9b80-debe6704dda9"          # az account show --query id
export AZURE_LOCATION="eastus2"                         # closest to Edmonton, AB

# ── Resource Group ─────────────────────────────────────────────────────────────
export RESOURCE_GROUP="sentimentmyresoursegrouprobel"



# ── Azure Container Registry ───────────────────────────────────────────────────

export ACR_NAME="sentimentregistryrobel1991"                           # must be globally unique, lowercase, no hyphens
export ACR_SERVER="${ACR_NAME}.azurecr.io"
export IMAGE_NAME="sentiment-fastapi-docker"
export IMAGE_TAG="latest"
export FULL_IMAGE="${ACR_SERVER}/${IMAGE_NAME}:${IMAGE_TAG}"


# ── Azure Blob Storage (model + data storage) ──────────────────────────────────
export STORAGE_ACCOUNT="sentimentmodelstor"   # globally unique, lowercase

# Container for ML models
export MODEL_CONTAINER="models"
export MODEL_FILENAME="llama-2-7b-chat-hf-q4_k_m.gguf"

# Container for datasets
export DATA_CONTAINER="data"
export DATA_FILENAME="imdb.csv"

# ── Local model path (update to your actual path) ─────────────────────────────
# On WSL, Windows paths become: /mnt/c/Users/...

export LOCAL_MODEL_PATH="/mnt/c/Robel_Al_ML_Projects_GRAND_DIRECTORY/Sentiment_Classification_Project_Root_Project_1/backend/model/${MODEL_FILENAME}"
export LOCAL_DATA_PATH="/mnt/c/Robel_Al_ML_Projects_GRAND_DIRECTORY/Sentiment_Classification_Project_Root_Project_1/backend/data/${DATA_FILENAME}"

# ── Azure Container Apps ───────────────────────────────────────────────────────
export ACA_ENV="sentiment-env"
export ACA_APP="sentiment-api"
export ACA_PORT="8080"
export ACA_MIN_REPLICAS="0"                                   # 0 = scale to zero (pay nothing when idle)
export ACA_MAX_REPLICAS="3"
export ACA_CPU="4.0"
export ACA_MEMORY="8.0Gi"

# ── GitHub (for CI/CD service principal scope) ─────────────────────────────────
export GITHUB_USERNAME="RobelBT-FL"
export GITHUB_BACKEND_REPO="Sentiment_Classification_from_local_backend"
export GITHUB_FRONTEND_REPO="sentiment-frontend"
export SP_NAME="github-actions-sentiment"                     # service principal name

# ── Cost Alert ─────────────────────────────────────────────────────────────────
export ALERT_EMAIL="robelberhe09@gmail.com"
export BUDGET_AMOUNT="15"                                     # alert at 80% of this USD amount

# ── Derived values (do not edit) ──────────────────────────────────────────────
export BACKEND_SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "✅ Config loaded. Resource Group: ${RESOURCE_GROUP} | ACR: ${ACR_SERVER}"
echo "   Location: ${AZURE_LOCATION} | App: ${ACA_APP}"
