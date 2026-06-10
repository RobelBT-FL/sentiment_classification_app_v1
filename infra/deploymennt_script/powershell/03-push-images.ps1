# ═══════════════════════════════════════════════════════════════════════════════
# 03-push-images.ps1 — Build & Push Backend + Frontend Docker Images to ACR
# Requires: 00-config.ps1 loaded first
# Safe to re-run. Overwrites existing images.
# ═══════════════════════════════════════════════════════════════════════════════

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════"
Write-Host "  Building & Pushing Docker Images to Azure Container Registry"
Write-Host "  ACR: $env:ACR_SERVER"
Write-Host "════════════════════════════════════════════════════════════"
Write-Host ""

# ─────────────────────────────────────────────────────────────
# Step 1 — Login to Azure Container Registry
# ─────────────────────────────────────────────────────────────

Write-Host "[INFO] Logging into ACR: $env:ACR_SERVER ..."
az acr login --name $env:ACR_NAME --output none
Write-Host "[OK] Logged into ACR."

# ─────────────────────────────────────────────────────────────
# Step 2 — Build Backend Image
# ─────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "[INFO] Building backend Docker image..."

docker build `
    -t backend-docker-sentiment:latest `
    -f "$PSScriptRoot/../../backend/Dockerfile.localB" `
    "$PSScriptRoot/../../backend"

Write-Host "[OK] Backend image built."

docker tag backend-docker-sentiment:latest $env:BACKEND_IMAGE
Write-Host "[OK] Backend image tagged for ACR."


# ─────────────────────────────────────────────────────────────
# Step 3 — Build Frontend Image
# ─────────────────────────────────────────────────────────────

# $PSScriptRoot = the folder where the script lives.
# So no matter where you run:

Write-Host ""
Write-Host "[INFO] Building frontend Docker image..."

docker build `
    -t frontend-docker-sentiment:latest `
    -f "$PSScriptRoot/../../frontend/Dockerfile.localF" `
    "$PSScriptRoot/../../frontend"

Write-Host "[OK] Frontend image built."

docker tag frontend-docker-sentiment:latest $env:FRONTEND_IMAGE
Write-Host "[OK] Frontend image tagged for ACR."

# ─────────────────────────────────────────────────────────────
# Step 4 — Push Images to ACR
# ─────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "[INFO] Pushing backend image to ACR..."
docker push $env:BACKEND_IMAGE
Write-Host "[OK] Backend image pushed."

Write-Host ""
Write-Host "[INFO] Pushing frontend image to ACR..."
docker push $env:FRONTEND_IMAGE
Write-Host "[OK] Frontend image pushed."

# ─────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════"
Write-Host "  ✅ Docker Images Built & Pushed Successfully!"
Write-Host "════════════════════════════════════════════════════════════"
Write-Host "  Backend Image : $env:BACKEND_IMAGE"
Write-Host "  Frontend Image: $env:FRONTEND_IMAGE"
Write-Host ""
Write-Host "Next step:"
Write-Host "    .\04-deploy-backend.ps1   ← deploy backend API to Azure"
Write-Host "════════════════════════════════════════════════════════════"
