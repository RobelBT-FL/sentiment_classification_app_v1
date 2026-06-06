#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# 04-deploy.sh — Create OR Update Azure Container App
# First run: creates the Container App from scratch
# Subsequent runs: deploys a new revision (rolling update, zero downtime)
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/00-config.sh"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ── Load SAS URL from file or environment ──────────────────────────────────────
SAS_FILE="${SCRIPT_DIR}/.model-sas-url.txt"
if [[ -z "${MODEL_SAS_URL:-}" ]]; then
  if [[ -f "${SAS_FILE}" ]]; then
    MODEL_SAS_URL=$(cat "${SAS_FILE}")
    info "Loaded MODEL_SAS_URL from ${SAS_FILE}"
  else
    error "MODEL_SAS_URL not set and ${SAS_FILE} not found.
    Run 02-upload-model.sh first to generate the SAS URL."
  fi
fi

# ── Generate revision suffix from timestamp ────────────────────────────────────
REVISION_SUFFIX="v$(date +%Y%m%d%H%M)"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Deploy to Azure Container Apps"
echo "  App      : ${ACA_APP}"
echo "  Image    : ${FULL_IMAGE}"
echo "  Revision : ${REVISION_SUFFIX}"
echo "  Replicas : ${ACA_MIN_REPLICAS} (min) → ${ACA_MAX_REPLICAS} (max)"
echo "  Resources: ${ACA_CPU} vCPU / ${ACA_MEMORY} RAM"
echo "════════════════════════════════════════════════════════════"
echo ""

# ── Check if app already exists ────────────────────────────────────────────────
APP_EXISTS=$(az containerapp show \
  --name "${ACA_APP}" \
  --resource-group "${RESOURCE_GROUP}" \
  --query name \
  --output tsv 2>/dev/null || echo "NOT_FOUND")

if [[ "${APP_EXISTS}" == "NOT_FOUND" ]]; then
  # ════════════════════════════════════════════════════════════
  # FIRST DEPLOYMENT — create the Container App
  # ════════════════════════════════════════════════════════════
  info "Container App not found. Creating for the first time..."

  # Retrieve ACR password
  ACR_PASSWORD=$(az acr credential show \
    --name "${ACR_NAME}" \
    --query "passwords[0].value" \
    --output tsv)

  az containerapp create \
    --name "${ACA_APP}" \
    --resource-group "${RESOURCE_GROUP}" \
    --environment "${ACA_ENV}" \
    --image "${FULL_IMAGE}" \
    --registry-server "${ACR_SERVER}" \
    --registry-username "${ACR_NAME}" \
    --registry-password "${ACR_PASSWORD}" \
    --target-port "${ACA_PORT}" \
    --ingress external \
    --min-replicas "${ACA_MIN_REPLICAS}" \
    --max-replicas "${ACA_MAX_REPLICAS}" \
    --cpu "${ACA_CPU}" \
    --memory "${ACA_MEMORY}" \
    --revision-suffix "${REVISION_SUFFIX}" \
    --timeout 240 \
    --env-vars \
      "LLAMA_MODEL_PATH=/app/model/llama-2-7b-chat.hf-q4_k_m.gguf" \
      "LOG_LEVEL=INFO" \
      "PORT=${ACA_PORT}" \
      "MODEL_SAS_URL=${MODEL_SAS_URL}" \
    --output none

  success "Container App '${ACA_APP}' created."

  # ── Configure HTTP scaling rule ────────────────────────────────────────────
  info "Configuring HTTP auto-scaling (1 replica per 5 concurrent requests)..."
  az containerapp update \
    --name "${ACA_APP}" \
    --resource-group "${RESOURCE_GROUP}" \
    --scale-rule-name "http-scaling" \
    --scale-rule-type "http" \
    --scale-rule-http-concurrency 5 \
    --output none
  success "Scaling rule configured."

else
  # ════════════════════════════════════════════════════════════
  # SUBSEQUENT DEPLOYMENT — update to new image revision
  # ════════════════════════════════════════════════════════════
  info "Container App '${ACA_APP}' exists. Deploying new revision..."

  az containerapp update \
    --name "${ACA_APP}" \
    --resource-group "${RESOURCE_GROUP}" \
    --image "${FULL_IMAGE}" \
    --min-replicas "${ACA_MIN_REPLICAS}" \
    --max-replicas "${ACA_MAX_REPLICAS}" \
    --revision-suffix "${REVISION_SUFFIX}" \
    --set-env-vars \
      "LLAMA_MODEL_PATH=/app/model/llama-2-7b-chat.hf-q4_k_m.gguf" \
      "LOG_LEVEL=INFO" \
      "PORT=${ACA_PORT}" \
      "MODEL_SAS_URL=${MODEL_SAS_URL}" \
    --output none

  success "New revision '${REVISION_SUFFIX}' deployed."
fi

# ── Get the live URL ───────────────────────────────────────────────────────────
info "Fetching live URL..."
FQDN=$(az containerapp show \
  --name "${ACA_APP}" \
  --resource-group "${RESOURCE_GROUP}" \
  --query "properties.configuration.ingress.fqdn" \
  --output tsv)

LIVE_URL="https://${FQDN}"

# ── Save URL for other scripts ─────────────────────────────────────────────────
echo "${LIVE_URL}" > "${SCRIPT_DIR}/.live-url.txt"

# ── Show revision history ──────────────────────────────────────────────────────
info "Current revisions:"
az containerapp revision list \
  --name "${ACA_APP}" \
  --resource-group "${RESOURCE_GROUP}" \
  --query "[].{Name:name, Active:properties.active, Traffic:properties.trafficWeight, Created:properties.createdTime}" \
  --output table

echo ""
echo "════════════════════════════════════════════════════════════"
echo -e "  ${GREEN}✅ Deployment Complete!${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "  🌐 Live API  : ${LIVE_URL}"
echo "  📖 API Docs  : ${LIVE_URL}/docs"
echo "  📊 Health    : ${LIVE_URL}/health"
echo ""
echo "  ⏳ First request will trigger model download (~5-15 mins cold start)"
echo "     Subsequent requests are fast."
echo ""
echo "  To stream live logs:"
echo "    bash 06-ops.sh logs"
echo ""
echo "  Next step: bash 05-github-cicd-setup.sh"
echo "════════════════════════════════════════════════════════════"
