# ═══════════════════════════════════════════════════════════════════════════════
# 08-frontend-cicd-setup.ps1 — Write Frontend CI/CD Workflow (Next.js)
# ═══════════════════════════════════════════════════════════════════════════════

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Info($msg)    { Write-Host "[INFO]  $msg" -ForegroundColor Cyan }
function Success($msg) { Write-Host "[OK]    $msg" -ForegroundColor Green }
function Fail($msg)    { Write-Host "[ERROR] $msg" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════"
Write-Host "  GitHub Actions CI/CD Setup — Frontend Pipeline Generator"
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
    "ACR_SERVER"
)

foreach ($v in $required) {
    if (-not (Get-ChildItem Env: | Where-Object { $_.Name -eq $v })) {
        Fail "Missing required config variable: $v"
    }
}

# ───────────────────────────────────────────────────────────────
# 2. Detect Git Repo Root (bulletproof)
# ───────────────────────────────────────────────────────────────
try {
    $RepoRoot = git rev-parse --show-toplevel
} catch {
    Fail "This folder is not inside a Git repository. Initialize Git first."
}

Info "Repo root detected: $RepoRoot"

# ───────────────────────────────────────────────────────────────
# 3. Write Frontend GitHub Actions Workflow
# ───────────────────────────────────────────────────────────────
$WorkflowDir = Join-Path $RepoRoot ".github\workflows"
New-Item -ItemType Directory -Force -Path $WorkflowDir | Out-Null
$WorkflowFile = Join-Path $WorkflowDir "frontend-deploy.yml"

@'
name: Frontend CI/CD — Build and Deploy Next.js to Azure

# -------------------------------------------------------------------
# WORKFLOW PURPOSE
# -------------------------------------------------------------------
# This GitHub Action handles the full CI/CD pipeline for the frontend:
# 1. TEST  → Validate the Next.js project builds
# 2. BUILD → Build Docker image using frontend-next/Dockerfile.localF
#            and inject NEXT_PUBLIC_API_URL at build time
# 3. PUSH  → Push the built image to Azure Container Registry (ACR)
# 4. DEPLOY → Deploy updated frontend container to Azure Container Apps
#
# Triggered automatically on every push to the main branch.
# -------------------------------------------------------------------

on:
  push:
    branches: [ main ]

env:
  ACR_IMAGE: ${{ secrets.ACR_LOGIN_SERVER }}/frontend-docker-sentiment

jobs:

  test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Install Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "18"

      - name: Install frontend dependencies
        working-directory: ./frontend-next
        run: |
          npm ci

      - name: Run frontend build check
        working-directory: ./frontend-next
        run: |
          echo "Running build check..."
          npm run build

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

      - name: Build and Push Frontend Docker Image
        uses: docker/build-push-action@v5
        with:
          context: ./frontend-next
          file: ./frontend-next/Dockerfile.localF
          push: true
          tags: |
            ${{ env.ACR_IMAGE }}:latest
          build-args: |
            NEXT_PUBLIC_API_URL=${{ secrets.NEXT_PUBLIC_API_URL }}

  deploy:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Azure Login
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Deploy Frontend to Azure Container Apps
        uses: azure/container-apps-deploy-action@v1
        with:
          containerAppName: sentiment-frontend-app
          resourceGroup: sentimentmyresoursehelen2012
          imageToDeploy: ${{ env.ACR_IMAGE }}:latest
'@ | Out-File -FilePath $WorkflowFile -Encoding utf8

Success "Frontend CI/CD workflow written to: $WorkflowFile"

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════"
Write-Host "  Frontend CI/CD Setup Complete!"
Write-Host "════════════════════════════════════════════════════════════"
Write-Host ""
