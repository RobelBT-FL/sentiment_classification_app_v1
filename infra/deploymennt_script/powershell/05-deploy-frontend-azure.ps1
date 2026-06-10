# ============================================================
# 05-deploy-frontend.ps1 — FINAL CLEAN VERSION
# Deploys frontend UI to Azure Container Apps
# Requires:
#     . .\00-config.ps1
# ============================================================

# Backend website
# $env:BACKEND_URL = "https://sentiment-backend-api-app.nicedune-b5b33eb3.eastus2.azurecontainerapps.io"

Write-Host ""
Write-Host "============================================================"
Write-Host "  Deploying Frontend UI to Azure Container Apps"
Write-Host "  App Name: $env:ACA_FRONTEND_APP"
Write-Host "============================================================"
Write-Host ""

# -------------------------------
# Validate required variables
# -------------------------------
$requiredVars = @(
    "RESOURCE_GROUP",
    "ACA_ENV",
    "ACA_FRONTEND_APP",
    "FRONTEND_IMAGE",
    "ACR_SERVER",
    "ACR_USERNAME",
    "ACR_PASSWORD",
    "BACKEND_URL"
)

foreach ($var in $requiredVars) {
    $value = [System.Environment]::GetEnvironmentVariable($var)
    if (-not $value) {
        Write-Host "[ERROR] Missing required variable: $var" -ForegroundColor Red
        exit 1
    }
}

Write-Host "[OK] All required environment variables found."
Write-Host ""

# -------------------------------
# Deploy Frontend Container App
# -------------------------------
Write-Host "[INFO] Deploying frontend container app..."

az containerapp create `
    --name $env:ACA_FRONTEND_APP `
    --resource-group $env:RESOURCE_GROUP `
    --environment $env:ACA_ENV `
    --image $env:FRONTEND_IMAGE `
    --target-port 3000 `
    --ingress external `
    --cpu $env:ACA_CPU `
    --memory $env:ACA_MEMORY `
    --min-replicas $env:ACA_MIN_REPLICAS `
    --max-replicas $env:ACA_MAX_REPLICAS `
    --env-vars `
        NEXT_PUBLIC_API_URL="$env:BACKEND_URL" `
    --registry-server $env:ACR_SERVER `
    --registry-username $env:ACR_USERNAME `
    --registry-password $env:ACR_PASSWORD `
    --output none

Write-Host "[OK] Frontend UI deployed."
Write-Host ""

# -------------------------------
# Fetch Frontend URL
# -------------------------------
Write-Host "[INFO] Fetching frontend URL..."

$frontendUrl = az containerapp show `
    --name $env:ACA_FRONTEND_APP `
    --resource-group $env:RESOURCE_GROUP `
    --query "properties.configuration.ingress.fqdn" `
    -o tsv

Write-Host ""
Write-Host "============================================================"
Write-Host "  Frontend Deployment Complete!"
Write-Host "============================================================"
Write-Host "  Frontend URL: https://$frontendUrl"
Write-Host ""
Write-Host "🎉 Your full app is now LIVE!"
Write-Host "============================================================"
