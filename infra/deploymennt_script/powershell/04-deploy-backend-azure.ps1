# ============================================================
# 04-deploy-backend-azure.ps1 — FINAL CLEAN VERSION
# Deploys backend API to Azure Container Apps
# Requires:
#     . .\00-config.ps1
# ============================================================

Write-Host ""
Write-Host "============================================================"
Write-Host "  Deploying Backend API to Azure Container Apps"
Write-Host "  App Name: $env:ACA_APP"
Write-Host "============================================================"
Write-Host ""

# -------------------------------
# Validate required variables
# -------------------------------
$requiredVars = @(
    "RESOURCE_GROUP",
    "ACA_ENV",
    "ACA_APP",
    "BACKEND_IMAGE",
    "ACR_SERVER",
    "ACR_USERNAME",
    "ACR_PASSWORD",
    "STORAGE_ACCOUNT",
    "MODEL_FILENAME"
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
# Deploy Backend Container App
# -------------------------------
Write-Host "[INFO] Deploying backend container app..."

az containerapp create `
    --name $env:ACA_APP `
    --resource-group $env:RESOURCE_GROUP `
    --environment $env:ACA_ENV `
    --image $env:BACKEND_IMAGE `
    --target-port 8000 `
    --ingress external `
    --cpu $env:ACA_CPU `
    --memory $env:ACA_MEMORY `
    --min-replicas $env:ACA_MIN_REPLICAS `
    --max-replicas $env:ACA_MAX_REPLICAS `
    --env-vars `
        MODEL_BLOB_PATH="models/$env:MODEL_FILENAME" `
        STORAGE_ACCOUNT_NAME="$env:STORAGE_ACCOUNT" `
    --registry-server $env:ACR_SERVER `
    --registry-username $env:ACR_USERNAME `
    --registry-password $env:ACR_PASSWORD `
    --output none

Write-Host "[OK] Backend API deployed."
Write-Host ""

# -------------------------------
# Fetch Backend URL
# -------------------------------
Write-Host "[INFO] Fetching backend URL..."

$backendUrl = az containerapp show `
    --name $env:ACA_APP `
    --resource-group $env:RESOURCE_GROUP `
    --query "properties.configuration.ingress.fqdn" `
    -o tsv

Write-Host ""
Write-Host "============================================================"
Write-Host "  Backend Deployment Complete!"
Write-Host "============================================================"
Write-Host "  Backend URL: https://$backendUrl"
Write-Host ""
Write-Host "Next step:"
Write-Host "    .\05-deploy-frontend.ps1   ← deploy frontend UI"
Write-Host "============================================================"
