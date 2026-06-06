#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# 01-azure-setup.sh — ONE-TIME SETUP
# Creates: Resource Group, ACR, Blob Storage, ACA Environment
# Run once. Safe to re-run (az create commands are idempotent).
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/00-config.sh"

# ── Colour helpers ─────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }

# ═══════════════════════════════════════════════════════════════════════════════
echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Azure One-Time Setup — LLaMA Sentiment API"
echo "  Location : ${AZURE_LOCATION}"
echo "  Group    : ${RESOURCE_GROUP}"
echo "════════════════════════════════════════════════════════════"
echo ""

# ── Step 1: Login check ────────────────────────────────────────────────────────
info "Checking Azure login status..."
if ! az account show &>/dev/null; then
  warn "Not logged in. Opening browser for az login..."
  az login
fi

CURRENT_SUB=$(az account show --query "name" --output tsv)
success "Logged in. Active subscription: ${CURRENT_SUB}"

if [[ "${AZURE_SUBSCRIPTION_ID}" != "YOUR_SUBSCRIPTION_ID" ]]; then
  info "Setting subscription to: ${AZURE_SUBSCRIPTION_ID}"
  az account set --subscription "${AZURE_SUBSCRIPTION_ID}"
  success "Subscription set."
else
  warn "AZURE_SUBSCRIPTION_ID not set in 00-config.sh — using default subscription."
fi

# ── Step 2: Resource Group ─────────────────────────────────────────────────────
info "Creating Resource Group: ${RESOURCE_GROUP} in ${AZURE_LOCATION}..."
az group create \
  --name "${RESOURCE_GROUP}" \
  --location "${AZURE_LOCATION}" \
  --output none
success "Resource Group '${RESOURCE_GROUP}' ready."

# ── Step 3: Azure Container Registry ──────────────────────────────────────────
info "Creating Azure Container Registry: ${ACR_NAME}..."
az acr create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${ACR_NAME}" \
  --sku Basic \
  --admin-enabled true \
  --output none
success "ACR '${ACR_NAME}' created."

# Retrieve and export ACR credentials
info "Fetching ACR credentials..."
export ACR_USERNAME=$(az acr credential show \
  --name "${ACR_NAME}" \
  --query username \
  --output tsv)

export ACR_PASSWORD=$(az acr credential show \
  --name "${ACR_NAME}" \
  --query "passwords[0].value" \
  --output tsv)

echo ""
echo "  ┌─────────────────────────────────────────────────────┐"
echo "  │  ACR Credentials (add to GitHub Secrets)            │"
echo "  │  ACR_LOGIN_SERVER : ${ACR_SERVER}         │"
echo "  │  ACR_USERNAME     : ${ACR_USERNAME}                  │"
echo "  │  ACR_PASSWORD     : ${ACR_PASSWORD:0:8}...           │"
echo "  └─────────────────────────────────────────────────────┘"
echo ""

# ── Step 4: Azure Blob Storage ─────────────────────────────────────────────────
info "Creating Storage Account: ${STORAGE_ACCOUNT}..."
az storage account create \
  --name "${STORAGE_ACCOUNT}" \
  --resource-group "${RESOURCE_GROUP}" \
  --location "${AZURE_LOCATION}" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --allow-blob-public-access false \
  --output none
success "Storage Account '${STORAGE_ACCOUNT}' created (all blobs private)."

# Create MODEL container
info "Creating private blob container for models: ${MODEL_CONTAINER}..."
az storage container create \
  --name "${MODEL_CONTAINER}" \
  --account-name "${STORAGE_ACCOUNT}" \
  --public-access off \
  --auth-mode login \
  --output none
success "Blob container '${MODEL_CONTAINER}' created (private)."

# Create DATA container
info "Creating private blob container for datasets: ${DATA_CONTAINER}..."
az storage container create \
  --name "${DATA_CONTAINER}" \
  --account-name "${STORAGE_ACCOUNT}" \
  --public-access off \
  --auth-mode login \
  --output none
success "Blob container '${DATA_CONTAINER}' created (private)."

# ── Step 5: Azure Container Apps Environment ───────────────────────────────────
info "Creating Azure Container Apps Environment: ${ACA_ENV}..."
info "This takes 2-3 minutes..."
az containerapp env create \
  --name "${ACA_ENV}" \
  --resource-group "${RESOURCE_GROUP}" \
  --location "${AZURE_LOCATION}" \
  --output none
success "ACA Environment '${ACA_ENV}' ready."

# ── Step 6: Cost Budget Alert ──────────────────────────────────────────────────
info "Creating monthly cost alert (80% of \$${BUDGET_AMOUNT} USD)..."
NEXT_MONTH=$(date -d "$(date +%Y-%m-01) +1 month" +%Y-%m-01 2>/dev/null \
  || date -v+1m -f "%Y-%m-%d" "$(date +%Y-%m-01)" +%Y-%m-01)
END_DATE=$(date -d "$(date +%Y-%m-01) +25 months" +%Y-%m-01 2>/dev/null \
  || date -v+25m -f "%Y-%m-%d" "$(date +%Y-%m-01)" +%Y-%m-01)

az consumption budget create \
  --amount "${BUDGET_AMOUNT}" \
  --budget-name "sentiment-monthly-budget" \
  --category Cost \
  --resource-group "${RESOURCE_GROUP}" \
  --time-grain Monthly \
  --start-date "${NEXT_MONTH}" \
  --end-date "${END_DATE}" \
  --contact-emails "${ALERT_EMAIL}" \
  --threshold 80 \
  --output none 2>/dev/null || warn "Budget alert skipped (may need billing permissions)."

# ── Summary ────────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════════════"
echo -e "  ${GREEN}✅ Setup Complete!${NC}"
echo "════════════════════════════════════════════════════════════"
echo "  Resource Group  : ${RESOURCE_GROUP}"
echo "  ACR             : ${ACR_SERVER}"
echo "  Blob Storage    : ${STORAGE_ACCOUNT}/${STORAGE_CONTAINER}"
echo "  ACA Environment : ${ACA_ENV}"
echo ""
echo "  Next steps:"
echo "    bash 02-upload-model.sh    ← upload your 9 GB model"
echo "    bash 03-build-push.sh      ← build & push Docker image"
echo "    bash 04-deploy.sh          ← deploy to Azure"
echo "════════════════════════════════════════════════════════════"
