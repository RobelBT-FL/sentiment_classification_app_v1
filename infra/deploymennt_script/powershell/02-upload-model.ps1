# ═══════════════════════════════════════════════════════════════════════════════
# 02-upload-model.ps1 — Upload GGUF Model + Dataset + Generate SAS URL
# Requires: 00-config.ps1 loaded first
# Safe to re-run. Overwrites existing blobs.
# ═══════════════════════════════════════════════════════════════════════════════

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════"
Write-Host "  Uploading Model + Dataset to Azure Blob Storage"
Write-Host "  Storage Account : $env:STORAGE_ACCOUNT"
Write-Host "  Model Container : $env:MODEL_CONTAINER"
Write-Host "  Data Container  : $env:DATA_CONTAINER"
Write-Host "════════════════════════════════════════════════════════════"
Write-Host ""

# ─────────────────────────────────────────────────────────────
# Step 1 — Validate local files
# ─────────────────────────────────────────────────────────────

if (-Not (Test-Path $env:LOCAL_MODEL_PATH)) {
    Write-Host "[ERROR] Model file not found at: $env:LOCAL_MODEL_PATH" -ForegroundColor Red
    exit 1
}

if (-Not (Test-Path $env:LOCAL_DATASET_PATH)) {
    Write-Host "[ERROR] Dataset file not found at: $env:LOCAL_DATASET_PATH" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Local model and dataset files found."

# ─────────────────────────────────────────────────────────────
# Step 2 — Upload GGUF Model
# ─────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "[INFO] Uploading GGUF model..."
Write-Host "       File: $env:LOCAL_MODEL_PATH"
Write-Host "       → Container: $env:MODEL_CONTAINER"

$ModelBlobName = Split-Path $env:LOCAL_MODEL_PATH -Leaf

az storage blob upload `
    --account-name $env:STORAGE_ACCOUNT `
    --container-name $env:MODEL_CONTAINER `
    --name $ModelBlobName `
    --file $env:LOCAL_MODEL_PATH `
    --auth-mode login `
    --overwrite true `
    --output none

Write-Host "[OK] Model uploaded successfully."

# ─────────────────────────────────────────────────────────────
# Step 3 — Upload Dataset
# ─────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "[INFO] Uploading dataset..."
Write-Host "       File: $env:LOCAL_DATASET_PATH"
Write-Host "       → Container: $env:DATA_CONTAINER"

$DatasetBlobName = Split-Path $env:LOCAL_DATASET_PATH -Leaf

az storage blob upload `
    --account-name $env:STORAGE_ACCOUNT `
    --container-name $env:DATA_CONTAINER `
    --name $DatasetBlobName `
    --file $env:LOCAL_DATASET_PATH `
    --auth-mode login `
    --overwrite true `
    --output none

Write-Host "[OK] Dataset uploaded successfully."

# ─────────────────────────────────────────────────────────────
# Step 4 — Generate SAS URL for model
# ─────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "[INFO] Generating SAS URL for model..."

$SAS_TOKEN = az storage blob generate-sas `
    --account-name $env:STORAGE_ACCOUNT `
    --container-name $env:MODEL_CONTAINER `
    --name $ModelBlobName `
    --permissions r `
    --expiry 2030-01-01 `
    --https-only `
    -o tsv

$MODEL_SAS_URL = "https://$($env:STORAGE_ACCOUNT).blob.core.windows.net/$($env:MODEL_CONTAINER)/$ModelBlobName`?$SAS_TOKEN"

$SAS_FILE = "$PSScriptRoot\.model-sas-url.txt"
$MODEL_SAS_URL | Out-File -FilePath $SAS_FILE -Encoding utf8

Write-Host "[OK] SAS URL generated and saved to:"
Write-Host "     $SAS_FILE"
Write-Host ""
Write-Host "MODEL_SAS_URL (copy this into GitHub Secrets):"
Write-Host $MODEL_SAS_URL -ForegroundColor Yellow

# ─────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════"
Write-Host "  ✅ Upload Complete!"
Write-Host "════════════════════════════════════════════════════════════"
Write-Host "  Model Blob : $env:MODEL_CONTAINER / $ModelBlobName"
Write-Host "  Dataset    : $env:DATA_CONTAINER / $DatasetBlobName"
Write-Host ""
Write-Host "Next step:"
Write-Host "    .\03-push-images.ps1   ← build & push backend + frontend Docker images"
Write-Host "════════════════════════════════════════════════════════════"
