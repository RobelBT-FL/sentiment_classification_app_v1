#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# 02-upload-model.sh — Upload LLaMA 2 13B model to Azure Blob Storage (PRIVATE)
# Run once. The model stays private — only accessible via SAS URL with your token.
# Upload takes 30-60 mins for 9 GB. Start this first, do other scripts while waiting.
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/00-config.sh"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Model Upload — LLaMA 2 13B → Azure Blob Storage (Private)"
echo "════════════════════════════════════════════════════════════"
echo ""

# ── Preflight checks ───────────────────────────────────────────────────────────
if [[ ! -f "${LOCAL_MODEL_PATH}" ]]; then
  error "Model file not found at: ${LOCAL_MODEL_PATH}

  Update LOCAL_MODEL_PATH in 00-config.sh to your actual GGUF file path.
  On WSL, Windows paths look like: /mnt/c/Users/YourName/..."
fi

MODEL_SIZE=$(du -sh "${LOCAL_MODEL_PATH}" | cut -f1)
info "Model found: ${LOCAL_MODEL_PATH} (${MODEL_SIZE})"

# >>> ADDED FOR DATA CONTAINER <<<
if [[ ! -f "${LOCAL_DATA_PATH}" ]]; then
  error "Dataset file not found at: ${LOCAL_DATA_PATH}"
fi

DATA_SIZE=$(du -sh "${LOCAL_DATA_PATH}" | cut -f1)
info "Dataset found: ${LOCAL_DATA_PATH} (${DATA_SIZE})"
# >>> END ADDITION <<<

if ! az account show &>/dev/null; then
  error "Not logged in to Azure. Run: az login"
fi

# ── Check if already uploaded ──────────────────────────────────────────────────
info "Checking if model already exists in Blob Storage..."
ALREADY_EXISTS=$(az storage blob exists \
  --account-name "${STORAGE_ACCOUNT}" \
  --container-name "${MODEL_CONTAINER}" \
  --name "${MODEL_FILENAME}" \
  --auth-mode login \
  --query exists \
  --output tsv 2>/dev/null || echo "false")

if [[ "${ALREADY_EXISTS}" == "true" ]]; then
  warn "Model already exists in Blob Storage!"
  read -r -p "  Re-upload? This overwrites the existing file. [y/N]: " CONFIRM
  if [[ ! "${CONFIRM}" =~ ^[Yy]$ ]]; then
    info "Skipping upload. Generating SAS URL for existing model..."
    SKIP_UPLOAD=true
  else
    SKIP_UPLOAD=false
  fi
else
  SKIP_UPLOAD=false
fi

# ── Upload model ───────────────────────────────────────────────────────────────
if [[ "${SKIP_UPLOAD}" == "false" ]]; then
  info "Starting upload of ${MODEL_FILENAME} (${MODEL_SIZE}) to Azure Blob..."
  info "This will take 30-60 minutes. You can run other scripts in a new terminal."
  echo ""

  az storage blob upload \
    --account-name "${STORAGE_ACCOUNT}" \
    --container-name "${MODEL_CONTAINER}" \
    --name "${MODEL_FILENAME}" \
    --file "${LOCAL_MODEL_PATH}" \
    --auth-mode login \
    --overwrite true \

  success "Model uploaded successfully to: ${STORAGE_ACCOUNT}/${MODEL_CONTAINER}/${MODEL_FILENAME}"
fi

# >>> ADDED FOR DATA CONTAINER — UPLOAD DATASET <<<
info "Uploading dataset to Azure Blob Storage..."

az storage blob upload \
  --account-name "${STORAGE_ACCOUNT}" \
  --container-name "${DATA_CONTAINER}" \
  --name "${DATA_FILENAME}" \
  --file "${LOCAL_DATA_PATH}" \
  --auth-mode login \
  --overwrite true

success "Dataset uploaded successfully to: ${STORAGE_ACCOUNT}/${DATA_CONTAINER}/${DATA_FILENAME}"
# >>> END ADDITION <<<

# ── Generate SAS URL (1-year expiry) ───────────────────────────────────────────
info "Generating private SAS URL (valid for 1 year)..."

if date --version &>/dev/null 2>&1; then
  EXPIRY=$(date -u -d "+1 year" +"%Y-%m-%dT%H:%MZ")
else
  EXPIRY=$(date -u -v+1y +"%Y-%m-%dT%H:%MZ")
fi

SAS_URL=$(az storage blob generate-sas \
  --account-name "${STORAGE_ACCOUNT}" \
  --container-name "${MODEL_CONTAINER}" \
  --name "${MODEL_FILENAME}" \
  --permissions r \
  --expiry "$(date -u -d '7 days' +%Y-%m-%dT%H:%MZ)" \
  --full-uri \
  --auth-mode login \
  --as-user \
  --output tsv)

SAS_FILE="${SCRIPT_DIR}/.model-sas-url.txt"
echo "${SAS_URL}" > "${SAS_FILE}"
chmod 600 "${SAS_FILE}"

echo ""
echo "════════════════════════════════════════════════════════════"
echo -e "  ${GREEN}✅ Upload Complete — Model + Dataset${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "  Model : ${MODEL_CONTAINER}/${MODEL_FILENAME}"
echo "  Data  : ${DATA_CONTAINER}/${DATA_FILENAME}"
echo ""
echo "  SAS URL saved to: ${SAS_FILE}"
echo "  SAS URL expires:  ${EXPIRY}"
echo ""
echo "Next step: bash 03-build-push.sh"
echo "════════════════════════════════════════════════════════════"
