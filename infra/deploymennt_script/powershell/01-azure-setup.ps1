# ═══════════════════════════════════════════════════════════════════════════════
# 01-azure-setup.ps1 — ONE-TIME AZURE SETUP (PowerShell Version)
# Creates: Resource Group, ACR, Storage Account, Blob Containers, ACA Environment
# Safe to re-run. All Azure create commands are idempotent.
# ═══════════════════════════════════════════════════════════════════════════════

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════"
Write-Host "  Azure One-Time Setup — LLaMA Sentiment API"
Write-Host "  Location : $env:AZURE_LOCATION"
Write-Host "  Group    : $env:RESOURCE_GROUP"
Write-Host "════════════════════════════════════════════════════════════"
Write-Host ""

# ─────────────────────────────────────────────────────────────
# Step 1 — Azure Login
# ─────────────────────────────────────────────────────────────
Write-Host "[INFO] Checking Azure login status..."

try {
    az account show | Out-Null
    Write-Host "[OK] Already logged in."
}
catch {
    Write-Host "[WARN] Not logged in. Opening browser..."
    az login | Out-Null
}

$CURRENT_SUB = az account show --query "name" -o tsv
Write-Host "[OK] Active subscription: $CURRENT_SUB"

Write-Host "[INFO] Setting subscription to $env:AZURE_SUBSCRIPTION_ID..."
az account set --subscription $env:AZURE_SUBSCRIPTION_ID
Write-Host "[OK] Subscription set."

# ─────────────────────────────────────────────────────────────
# Step 2 — Resource Group
# ─────────────────────────────────────────────────────────────
Write-Host "[INFO] Creating Resource Group: $env:RESOURCE_GROUP ..."
az group create `
    --name $env:RESOURCE_GROUP `
    --location $env:AZURE_LOCATION `
    --output none
Write-Host "[OK] Resource Group ready."

# ─────────────────────────────────────────────────────────────
# Step 3 — Azure Container Registry (ACR)
# ─────────────────────────────────────────────────────────────
Write-Host "[INFO] Creating Azure Container Registry: $env:ACR_NAME ..."
az acr create `
    --resource-group $env:RESOURCE_GROUP `
    --name $env:ACR_NAME `
    --sku Basic `
    --admin-enabled true `
    --output none
Write-Host "[OK] ACR created."

# Retrieve ACR credentials
Write-Host "[INFO] Fetching ACR credentials..."
$env:ACR_USERNAME = az acr credential show `
    --name $env:ACR_NAME `
    --query username `
    -o tsv

$env:ACR_PASSWORD = az acr credential show `
    --name $env:ACR_NAME `
    --query "passwords[0].value" `
    -o tsv

Write-Host ""
Write-Host "  ┌────────────────────────────────────────────────────────────┐"
Write-Host "  │  ACR Credentials (Add to GitHub Secrets)                   │"
Write-Host "  │  ACR_LOGIN_SERVER : $env:ACR_SERVER                        │"
Write-Host "  │  ACR_USERNAME     : $env:ACR_USERNAME                      │"
Write-Host "  │  ACR_PASSWORD     : $($env:ACR_PASSWORD.Substring(0,8))... │"
Write-Host "  └────────────────────────────────────────────────────────────┘"
Write-Host ""

# ─────────────────────────────────────────────────────────────
# Step 4 — Storage Account + Blob Containers
# ─────────────────────────────────────────────────────────────
Write-Host "[INFO] Creating Storage Account: $env:STORAGE_ACCOUNT ..."
az storage account create `
    --name $env:STORAGE_ACCOUNT `
    --resource-group $env:RESOURCE_GROUP `
    --location $env:AZURE_LOCATION `
    --sku Standard_LRS `
    --kind StorageV2 `
    --allow-blob-public-access false `
    --output none
Write-Host "[OK] Storage Account created."

# Create model container
Write-Host "[INFO] Creating model container: $env:MODEL_CONTAINER ..."
az storage container create `
    --name $env:MODEL_CONTAINER `
    --account-name $env:STORAGE_ACCOUNT `
    --public-access off `
    --auth-mode login `
    --output none
Write-Host "[OK] Model container created."

# Create data container
Write-Host "[INFO] Creating data container: $env:DATA_CONTAINER ..."
az storage container create `
    --name $env:DATA_CONTAINER `
    --account-name $env:STORAGE_ACCOUNT `
    --public-access off `
    --auth-mode login `
    --output none
Write-Host "[OK] Data container created."

# ─────────────────────────────────────────────────────────────
# Step 5 — Azure Container Apps Environment
# ─────────────────────────────────────────────────────────────
Write-Host "[INFO] Creating Azure Container Apps Environment: $env:ACA_ENV ..."
Write-Host "[INFO] This may take 2–3 minutes..."

az containerapp env create `
    --name $env:ACA_ENV `
    --resource-group $env:RESOURCE_GROUP `
    --location $env:AZURE_LOCATION `
    --output none

Write-Host "[OK] ACA Environment created."

# ─────────────────────────────────────────────────────────────
# Step 6 — Cost Budget Alert (NEW JSON FORMAT)
# ─────────────────────────────────────────────────────────────
Write-Host "[INFO] Creating monthly cost alert..."

$StartDate = (Get-Date -Day 1).AddMonths(1).ToString("yyyy-MM-dd")
$EndDate   = (Get-Date -Day 1).AddMonths(25).ToString("yyyy-MM-dd")

try {
    az consumption budget create `
        --budget-name "sentiment-monthly-budget" `
        --resource-group $env:RESOURCE_GROUP `
        --amount $env:BUDGET_AMOUNT `
        --time-grain Monthly `
        --category Cost `
        --start-date $StartDate `
        --end-date $EndDate `
        --notifications "{
            `"Actual_GreaterThan_80_Percent`": {
                `"enabled`": true,
                `"operator`": `"GreaterThan`",
                `"threshold`": 80,
                `"contactEmails`": [ `"$env:ALERT_EMAIL`" ]
            }
        }"

    Write-Host "[OK] Cost alert created."
}
catch {
    Write-Host "[WARN] Could not create cost alert (billing permissions required)."
}

# ─────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════"
Write-Host "  ✅ Azure Setup Complete!"
Write-Host "════════════════════════════════════════════════════════════"
Write-Host "  Resource Group  : $env:RESOURCE_GROUP"
Write-Host "  ACR             : $env:ACR_SERVER"
Write-Host "  Storage Account : $env:STORAGE_ACCOUNT"
Write-Host "  ACA Environment : $env:ACA_ENV"
Write-Host ""
Write-Host "  Next steps:"
Write-Host "    .\02-upload-model.ps1     ← upload your GGUF model"
Write-Host "    .\03-push-images.ps1      ← push backend + frontend images"
Write-Host "    .\04-deploy-backend.ps1   ← deploy backend API"
Write-Host "    .\05-deploy-frontend.ps1  ← deploy frontend UI"
Write-Host "════════════════════════════════════════════════════════════"
