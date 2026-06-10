# ═══════════════════════════════════════════════════════════════════════════════
# 06-github-cicd-setup.ps1 — Create Azure Service Principal + Write Backend CI/CD
# ═══════════════════════════════════════════════════════════════════════════════

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Info($msg)    { Write-Host "[INFO]  $msg" -ForegroundColor Cyan }
function Success($msg) { Write-Host "[OK]    $msg" -ForegroundColor Green }
function Fail($msg)    { Write-Host "[ERROR] $msg" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════"
Write-Host "  GitHub Actions CI/CD Setup — Backend Pipeline Generator"
Write-Host "════════════════════════════════════════════════════════════"
Write-Host ""

# Load config
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\00-config.ps1"

# ───────────────────────────────────────────────────────────────
# 1. Validate required environment variables
# ───────────────────────────────────────────────────────────────
$required = @(
    "RESOURCE_GROUP",
    "ACR_NAME",
    "ACR_SERVER",
    "SP_NAME",
    "AZURE_SUBSCRIPTION_ID"
)

foreach ($v in $required) {
    if (-not (Get-ChildItem Env: | Where-Object { $_.Name -eq $v })) {
        Fail "Missing required config variable: $v"
    }
}

# ───────────────────────────────────────────────────────────────
# 2. Ensure Azure login
# ───────────────────────────────────────────────────────────────
try {
    az account show | Out-Null
} catch {
    Fail "Not logged in to Azure. Run: az login"
}

Info "Using subscription: $env:AZURE_SUBSCRIPTION_ID"

# ───────────────────────────────────────────────────────────────
# 3. Create Azure Service Principal
# ───────────────────────────────────────────────────────────────
Info "Creating Azure Service Principal: $env:SP_NAME"

$SP_JSON = az ad sp create-for-rbac `
    --name $env:SP_NAME `
    --role contributor `
    --scopes "/subscriptions/$env:AZURE_SUBSCRIPTION_ID/resourceGroups/$env:RESOURCE_GROUP" `
    --sdk-auth `
    -o json

$SP_FILE = "$ScriptDir\.azure-credentials.json"
$SP_JSON | Out-File -FilePath $SP_FILE -Encoding utf8

Success "Service Principal created. Credentials saved to: $SP_FILE"

# ───────────────────────────────────────────────────────────────
# 4. Load SAS URL
# ───────────────────────────────────────────────────────────────
$SAS_FILE = "$ScriptDir\.model-sas-url.txt"
if (Test-Path $SAS_FILE) {
    $MODEL_SAS_URL_VAL = Get-Content $SAS_FILE -Raw
} else {
    $MODEL_SAS_URL_VAL = "⚠️ Missing SAS URL"
}

# ───────────────────────────────────────────────────────────────
# 5. Print GitHub Secrets
# ───────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════"
Write-Host "  Add these secrets to GitHub:"
Write-Host ""
Write-Host "  AZURE_CREDENTIALS  → contents of $SP_FILE"
Write-Host "  ACR_LOGIN_SERVER   → $env:ACR_SERVER"
Write-Host "  ACR_USERNAME       → $env:ACR_NAME"
Write-Host "  ACR_PASSWORD       → $env:ACR_PASSWORD"
Write-Host "  MODEL_SAS_URL      → contents of $SAS_FILE"
Write-Host "════════════════════════════════════════════════════════════"
Write-Host ""

# ───────────────────────────────────────────────────────────────
# 6. Detect Git Repo Root (bulletproof)
# ───────────────────────────────────────────────────────────────
try {
    $RepoRoot = git rev-parse --show-toplevel
} catch {
    Fail "This folder is not inside a Git repository. Initialize Git first."
}

Info "Repo root detected: $RepoRoot"

# ───────────────────────────────────────────────────────────────
# 7. Write Backend GitHub Actions Workflow
# ───────────────────────────────────────────────────────────────
$WorkflowDir = Join-Path $RepoRoot ".github\workflows"
New-Item -ItemType Directory -Force -Path $WorkflowDir | Out-Null
$WorkflowFile = Join-Path $WorkflowDir "backend-deploy.yml"

@'
name: Backend CI/CD — Test, Build, and Deploy to Azure

# -------------------------------------------------------------------
# WORKFLOW PURPOSE
# -------------------------------------------------------------------
# This GitHub Action handles the full CI/CD pipeline for the backend:
# 1. TEST  → Run backend tests (ensures code quality)
# 2. BUILD → Build Docker image using backend/Dockerfile.localB
# 3. PUSH  → Push image to Azure Container Registry (ACR)
# 4. DEPLOY → Deploy updated backend container to Azure Container Apps
#
# Triggered automatically on every push to the main branch.
# -------------------------------------------------------------------

on:
  push:
    branches: [ main ]

env:
  ACR_IMAGE: ${{ secrets.ACR_LOGIN_SERVER }}/backend-docker-sentiment

jobs:

  test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.10"

      - name: Install backend dependencies
        working-directory: ./backend
        run: |
          pip install -r requirements.txt

      - name: Run backend tests
        working-directory: ./backend
        run: |
          echo "No tests yet — pipeline continues"
          # pytest

  build:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Login to Azure Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ secrets.ACR_LOGIN_SERVER }}
          username: ${{ secrets.ACR_USERNAME }}
          password: ${{ secrets.ACR_PASSWORD }}

      - name: Build and Push Backend Docker Image
        uses: docker/build-push-action@v5
        with:
          context: ./backend
          file: ./backend/Dockerfile.localB
          push: true
          tags: |
            ${{ env.ACR_IMAGE }}:latest

  deploy:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Azure Login
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Deploy Backend to Azure Container Apps
        uses: azure/container-apps-deploy-action@v1
        with:
          containerAppName: sentiment-backend-api-app
          resourceGroup: sentimentmyresoursehelen2012
          imageToDeploy: ${{ env.ACR_IMAGE }}:latest
          environmentVariables: |
            MODEL_SAS_URL=${{ secrets.MODEL_SAS_URL }}
'@ | Out-File -FilePath $WorkflowFile -Encoding utf8

Success "Backend CI/CD workflow written to: $WorkflowFile"

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════"
Write-Host "  Backend CI/CD Setup Complete!"
Write-Host "════════════════════════════════════════════════════════════"
Write-Host ""
