# ============================================================
# azure-full-clean.ps1 — FULL AZURE CLEANUP SCRIPT
# Deletes ALL resources for the sentiment app project.
# ============================================================

Write-Host ""
Write-Host "============================================================"
Write-Host "  Azure Full Cleanup — Sentiment App Project"
Write-Host "============================================================"
Write-Host ""

# -------------------------------
# Load config if available
# -------------------------------
if (Test-Path ".\00-config.ps1") {
    . .\00-config.ps1
    Write-Host "[INFO] Loaded config file."
} else {
    Write-Host "[WARNING] 00-config.ps1 not found. Using default names."
}

# -------------------------------
# Resource Group
# -------------------------------
$resourceGroup = $env:RESOURCE_GROUP
if (-not $resourceGroup) {
    $resourceGroup = "sentimentmyresoursehelen2012"
}

Write-Host "[INFO] Resource Group to delete: $resourceGroup"
Write-Host ""

# -------------------------------
# Confirm deletion
# -------------------------------
Write-Host "This will DELETE ALL Azure resources in:"
Write-Host "   Resource Group: $resourceGroup"
Write-Host ""
Write-Host "Press CTRL+C to cancel."
Start-Sleep -Seconds 5

# -------------------------------
# Delete Resource Group
# -------------------------------
Write-Host "[INFO] Deleting resource group..."
az group delete `
    --name $resourceGroup `
    --yes `
    --no-wait

Write-Host ""
Write-Host "[OK] Delete request sent."
Write-Host "Azure will remove all resources in the background."
Write-Host ""

# -------------------------------
# Optional: Clean role assignments
# -------------------------------
Write-Host "[INFO] Cleaning role assignments for ACR Pull..."

try {
    $acrName = $env:ACR_NAME
    if ($acrName) {
        $acrId = az acr show --name $acrName --query id -o tsv 2>$null
        if ($acrId) {
            az role assignment delete --scope $acrId --yes 2>$null
            Write-Host "[OK] ACR role assignments removed."
        }
    }
} catch {
    Write-Host "[INFO] No ACR role assignments found."
}

Write-Host ""
Write-Host "============================================================"
Write-Host "  Azure Cleanup Complete (Background Deletion Running)"
Write-Host "============================================================"
Write-Host ""
Write-Host "You can now safely recreate everything from scratch."
Write-Host ""
Write-Host "Next step:"
Write-Host "   .\00-config.ps1"
Write-Host "   .\01-azure-setup.ps1"
Write-Host ""
Write-Host "============================================================"
