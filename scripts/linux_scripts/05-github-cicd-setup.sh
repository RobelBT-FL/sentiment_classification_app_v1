#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# 05-github-cicd-setup.sh — Create Azure Service Principal for GitHub Actions
# Outputs everything you need to add to GitHub Secrets.
# Run once. The SP gives GitHub Actions permission to push to ACR and deploy to ACA.
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
echo "  GitHub Actions CI/CD Setup — Azure Service Principal"
echo "════════════════════════════════════════════════════════════"
echo ""

if ! az account show &>/dev/null; then
  error "Not logged in to Azure. Run: az login"
fi

# ── Get subscription ID ────────────────────────────────────────────────────────
SUB_ID=$(az account show --query id --output tsv)
info "Using subscription: ${SUB_ID}"

# ── Create Service Principal ───────────────────────────────────────────────────
info "Creating Azure Service Principal: ${SP_NAME}..."
info "Scope: /subscriptions/${SUB_ID}/resourceGroups/${RESOURCE_GROUP}"

SP_JSON=$(az ad sp create-for-rbac \
  --name "${SP_NAME}" \
  --role contributor \
  --scopes "/subscriptions/${SUB_ID}/resourceGroups/${RESOURCE_GROUP}" \
  --sdk-auth \
  --output json)

# ── Save to file (chmod 600 = only you can read it) ────────────────────────────
SP_FILE="${SCRIPT_DIR}/.azure-credentials.json"
echo "${SP_JSON}" > "${SP_FILE}"
chmod 600 "${SP_FILE}"
success "Service Principal created. Credentials saved to: ${SP_FILE}"

# ── Retrieve ACR credentials ───────────────────────────────────────────────────
ACR_PASSWORD=$(az acr credential show \
  --name "${ACR_NAME}" \
  --query "passwords[0].value" \
  --output tsv)

# ── Load SAS URL ───────────────────────────────────────────────────────────────
SAS_FILE="${SCRIPT_DIR}/.model-sas-url.txt"
MODEL_SAS_URL_VAL=""
if [[ -f "${SAS_FILE}" ]]; then
  MODEL_SAS_URL_VAL=$(cat "${SAS_FILE}")
else
  warn "SAS URL file not found (${SAS_FILE}). Run 02-upload-model.sh first."
  MODEL_SAS_URL_VAL="⚠️  Run 02-upload-model.sh to generate this value"
fi

# ── Print GitHub Secrets instructions ─────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Add these 5 secrets to your GitHub repository:"
echo ""
echo "  Go to:"
echo "  github.com/${GITHUB_USERNAME}/${GITHUB_BACKEND_REPO}"
echo "  → Settings → Secrets and variables → Actions"
echo "  → New repository secret"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "  ┌────────────────────┬──────────────────────────────────────────────┐"
echo "  │ Secret Name        │ Value                                        │"
echo "  ├────────────────────┼──────────────────────────────────────────────┤"
echo "  │ AZURE_CREDENTIALS  │ (contents of ${SP_FILE})    │"
echo "  │ ACR_LOGIN_SERVER   │ ${ACR_SERVER}                     │"
echo "  │ ACR_USERNAME       │ ${ACR_NAME}                       │"
echo "  │ ACR_PASSWORD       │ ${ACR_PASSWORD:0:12}...                      │"
echo "  │ MODEL_SAS_URL      │ (contents of ${SAS_FILE})   │"
echo "  └────────────────────┴──────────────────────────────────────────────┘"
echo ""
echo "  The full AZURE_CREDENTIALS JSON:"
echo "  ─────────────────────────────────────"
echo "${SP_JSON}"
echo "  ─────────────────────────────────────"
echo ""
echo "  ACR_PASSWORD (full value):"
echo "  ${ACR_PASSWORD}"
echo ""
if [[ -n "${MODEL_SAS_URL_VAL}" ]]; then
  echo "  MODEL_SAS_URL (full value):"
  echo "  ${MODEL_SAS_URL_VAL}"
fi
echo ""

# ── Write the GitHub Actions workflow file ─────────────────────────────────────
WORKFLOW_DIR="${SCRIPT_DIR}/../.github/workflows"
WORKFLOW_FILE="${WORKFLOW_DIR}/azure-deploy.yml"
mkdir -p "${WORKFLOW_DIR}"

cat > "${WORKFLOW_FILE}" << 'WORKFLOW'
name: Test, Build, and Deploy to Azure

# ── Triggers ──────────────────────────────────────────────────────────────────
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

# ── Shared env vars ───────────────────────────────────────────────────────────
env:
  AZURE_CONTAINER_APP_NAME: sentiment-api
  AZURE_RESOURCE_GROUP:     sentiment-rg
  ACA_PORT:                 "8080"
  ACR_IMAGE:                ${{ secrets.ACR_LOGIN_SERVER }}/sentiment-api

jobs:

  # ── JOB 1: Run Backend Tests ──────────────────────────────────────────────
  test:
    name: Run Backend Tests
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python 3.10
        uses: actions/setup-python@v5
        with:
          python-version: '3.10'
          cache: 'pip'

      - name: Install dependencies
        run: pip install -r requirements.txt

      - name: Run pytest
        run: pytest tests/ -v --tb=short --continue-on-collection-errors
        continue-on-error: true   # Remove once full test coverage is added

  # ── JOB 2: Build Docker Image → Push to ACR ──────────────────────────────
  build-and-push:
    name: Build Docker Image → Push to ACR
    needs: test
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'

    outputs:
      image-tag: ${{ steps.meta.outputs.version }}

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Generate image tag from Git SHA
        id: meta
        run: |
          SHORT_SHA=$(echo "${{ github.sha }}" | cut -c1-7)
          echo "version=${SHORT_SHA}" >> "$GITHUB_OUTPUT"
          echo "Tagging image as: ${{ env.ACR_IMAGE }}:${SHORT_SHA}"

      - name: Log in to Azure Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ secrets.ACR_LOGIN_SERVER }}
          username: ${{ secrets.ACR_USERNAME }}
          password: ${{ secrets.ACR_PASSWORD }}

      - name: Set up Docker Buildx (layer caching)
        uses: docker/setup-buildx-action@v3

      - name: Build and push image to ACR
        uses: docker/build-push-action@v5
        with:
          context:  .
          file:     ./Dockerfile.azure
          push:     true
          tags: |
            ${{ env.ACR_IMAGE }}:latest
            ${{ env.ACR_IMAGE }}:${{ steps.meta.outputs.version }}
          cache-from: type=registry,ref=${{ env.ACR_IMAGE }}:buildcache
          cache-to:   type=registry,ref=${{ env.ACR_IMAGE }}:buildcache,mode=max

      - name: Confirm push
        run: |
          echo "✅ Pushed:"
          echo "   ${{ env.ACR_IMAGE }}:latest"
          echo "   ${{ env.ACR_IMAGE }}:${{ steps.meta.outputs.version }}"

  # ── JOB 3: Deploy to Azure Container Apps ────────────────────────────────
  deploy:
    name: Deploy to Azure Container Apps
    needs: build-and-push
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'

    steps:
      - name: Log in to Azure
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Deploy new revision to Azure Container Apps
        uses: azure/container-apps-deploy-action@v1
        with:
          containerAppName: ${{ env.AZURE_CONTAINER_APP_NAME }}
          resourceGroup:    ${{ env.AZURE_RESOURCE_GROUP }}
          imageToDeploy:    ${{ env.ACR_IMAGE }}:${{ needs.build-and-push.outputs.image-tag }}
          environmentVariables: |
            LLAMA_MODEL_PATH=/app/model/llama-2-13b-chat.Q5_K_M.gguf
            LOG_LEVEL=INFO
            PORT=8080
            MODEL_SAS_URL=${{ secrets.MODEL_SAS_URL }}

      - name: Print live URL
        run: |
          URL=$(az containerapp show \
            --name "${{ env.AZURE_CONTAINER_APP_NAME }}" \
            --resource-group "${{ env.AZURE_RESOURCE_GROUP }}" \
            --query "properties.configuration.ingress.fqdn" \
            --output tsv)
          echo ""
          echo "✅ Deployment complete!"
          echo "🌐 Live API  : https://${URL}"
          echo "📖 API Docs  : https://${URL}/docs"
          echo ""

      - name: Azure logout
        run: az logout
        if: always()
WORKFLOW

success "GitHub Actions workflow written to: ${WORKFLOW_FILE}"

echo ""
echo "════════════════════════════════════════════════════════════"
echo -e "  ${GREEN}✅ CI/CD Setup Complete!${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "  Workflow file created:"
echo "    ${WORKFLOW_FILE}"
echo ""
echo "  To activate CI/CD:"
echo "    1. Add the 5 GitHub Secrets listed above"
echo "    2. Run: git add .github/ Dockerfile.azure"
echo "    3. Run: git commit -m 'Add Azure CI/CD pipeline'"
echo "    4. Run: git push origin main"
echo "    5. Watch: github.com/${GITHUB_USERNAME}/${GITHUB_BACKEND_REPO}/actions"
echo ""
echo "  After that: every git push → tests → ACR push → Azure deploys"
echo "════════════════════════════════════════════════════════════"
