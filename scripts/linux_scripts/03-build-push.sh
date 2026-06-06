#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# 03-build-push.sh — Build Dockerfile.azure → Push to Azure Container Registry
# Run this manually for first deploy, then CI/CD handles it on every git push.
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/00-config.sh"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ── Optional: pass a custom tag as argument, e.g.: bash 03-build-push.sh v1.2.0
CUSTOM_TAG="${1:-}"
SHORT_SHA=$(git -C "${SCRIPT_DIR}" rev-parse --short HEAD 2>/dev/null || echo "manual")
VERSION_TAG="${CUSTOM_TAG:-${SHORT_SHA}}"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Build & Push Docker Image to ACR"
echo "  Image  : ${FULL_IMAGE}"
echo "  Version: ${ACR_SERVER}/${IMAGE_NAME}:${VERSION_TAG}"
echo "════════════════════════════════════════════════════════════"
echo ""

# ── Preflight checks ───────────────────────────────────────────────────────────
DOCKERFILE_PATH="${SCRIPT_DIR}/../Sentiment_Classification_Project_Root_Project_1/backend/Dockerfile.azure"
if [[ ! -f "${DOCKERFILE_PATH}" ]]; then
  error "Dockerfile.azure not found at: ${DOCKERFILE_PATH}
  Make sure Dockerfile.azure is in your backend/ folder."
fi

if ! az account show &>/dev/null; then
  error "Not logged in to Azure. Run: az login"
fi

if ! docker info &>/dev/null; then
  error "Docker is not running. Please start Docker Desktop."
fi

# ── Login to ACR ───────────────────────────────────────────────────────────────
info "Logging in to Azure Container Registry: ${ACR_SERVER}..."
az acr login --name "${ACR_NAME}"
success "ACR login successful."

# ── Build Docker image ─────────────────────────────────────────────────────────
info "Building Docker image using Dockerfile.azure..."
info "Context: ${SCRIPT_DIR}/../Sentiment_Classification_Project_Root_Project_1/backend"
echo ""

docker build \
  --file "${DOCKERFILE_PATH}" \
  --tag "${ACR_SERVER}/${IMAGE_NAME}:latest" \
  --tag "${ACR_SERVER}/${IMAGE_NAME}:${VERSION_TAG}" \
  --progress plain \
  "${SCRIPT_DIR}/../Sentiment_Classification_Project_Root_Project_1/backend"

echo ""
success "Docker image built successfully."
echo "  Tags:"
echo "    ${ACR_SERVER}/${IMAGE_NAME}:latest"
echo "    ${ACR_SERVER}/${IMAGE_NAME}:${VERSION_TAG}"

# ── Push to ACR ────────────────────────────────────────────────────────────────
info "Pushing image to ACR (this may take a few minutes)..."
docker push "${ACR_SERVER}/${IMAGE_NAME}:latest"
docker push "${ACR_SERVER}/${IMAGE_NAME}:${VERSION_TAG}"

success "Image pushed to ACR."

# ── Verify in ACR ──────────────────────────────────────────────────────────────
info "Verifying image tags in ACR..."
az acr repository show-tags \
  --name "${ACR_NAME}" \
  --repository "${IMAGE_NAME}" \
  --orderby time_desc \
  --output table

echo ""
echo "════════════════════════════════════════════════════════════"
echo -e "  ${GREEN}✅ Build & Push Complete!${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "  ACR Image (latest) : ${ACR_SERVER}/${IMAGE_NAME}:latest"
echo "  ACR Image (version): ${ACR_SERVER}/${IMAGE_NAME}:${VERSION_TAG}"
echo ""
echo "  Next step: bash 04-deploy.sh"
echo "════════════════════════════════════════════════════════════"
