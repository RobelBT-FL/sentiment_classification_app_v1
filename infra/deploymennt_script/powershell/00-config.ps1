# ============================================================
# 00-config.ps1 — Azure Deployment Configuration (CLEAN VERSION)
# Load using:
#     . .\00-config.ps1
# ============================================================

# -------------------------------
# SECTION 1 — Azure Identity
# -------------------------------
$env:AZURE_SUBSCRIPTION_ID = "54ba9555-5ee7-47a1-9b80-debe6704dda9"
$env:AZURE_LOCATION = "eastus2"

# -------------------------------
# SECTION 2 — Resource Group
# -------------------------------
$env:RESOURCE_GROUP = "sentimentmyresoursehelen2012"

# -------------------------------
# SECTION 3 — Azure Container Registry (ACR)
# -------------------------------
$env:ACR_NAME   = "sentimentacrregistryhelen2012"
$env:ACR_SERVER = "$($env:ACR_NAME).azurecr.io"

# ACR credentials
$env:ACR_USERNAME = $env:ACR_NAME
$env:ACR_PASSWORD = (az acr credential show --name $env:ACR_NAME --query "passwords[0].value" -o tsv)

# Backend image
$env:BACKEND_IMAGE_NAME = "backend-docker-sentiment"
$env:BACKEND_IMAGE_TAG  = "latest"
$env:BACKEND_FULL_IMAGE = "$($env:ACR_SERVER)/$($env:BACKEND_IMAGE_NAME):$($env:BACKEND_IMAGE_TAG)"
$env:BACKEND_IMAGE      = $env:BACKEND_FULL_IMAGE

# Frontend image
$env:FRONTEND_IMAGE_NAME = "frontend-docker-sentiment"
$env:FRONTEND_IMAGE_TAG  = "latest"
$env:FRONTEND_FULL_IMAGE = "$($env:ACR_SERVER)/$($env:FRONTEND_IMAGE_NAME):$($env:FRONTEND_IMAGE_TAG)"
$env:FRONTEND_IMAGE      = $env:FRONTEND_FULL_IMAGE

# -------------------------------
# SECTION 4 — Azure Blob Storage
# -------------------------------
$env:STORAGE_ACCOUNT = "sentimentstore2012"
$env:MODEL_CONTAINER = "models"
$env:MODEL_FILENAME  = "llama-2-7b-chat-hf-q4_k_m.gguf"
$env:DATA_CONTAINER  = "data"
$env:DATA_FILENAME   = "imdb.csv"

# -------------------------------
# SECTION 5 — Local Paths
# -------------------------------
$env:LOCAL_MODEL_PATH  = "C:\Users\robel\Robel_AI_ML_Projects\project_app\sentiment_classification_app_v1\models\$($env:MODEL_FILENAME)"
$env:LOCAL_DATASET_PATH = "C:\Users\robel\Robel_AI_ML_Projects\project_app\sentiment_classification_app_v1\data\$($env:DATA_FILENAME)"

# -------------------------------
# SECTION 6 — Azure Container Apps
# -------------------------------
# Backend ACA
$env:ACA_ENV = "sentiment-aca-env"
$env:ACA_APP = "sentiment-backend-api-app"
$env:ACA_PORT = "8000"
$env:ACA_MIN_REPLICAS = "0"
$env:ACA_MAX_REPLICAS = "3"
$env:ACA_CPU = "2.0"
$env:ACA_MEMORY = "4Gi"

# Frontend ACA
$env:ACA_FRONTEND_APP = "sentiment-frontend-app"
$env:ACA_FRONTEND_PORT = "3000"
$env:ACA_FRONTEND_MIN_REPLICAS = "0"
$env:ACA_FRONTEND_MAX_REPLICAS = "3"
$env:ACA_FRONTEND_CPU = "1.0"
$env:ACA_FRONTEND_MEMORY = "2.0Gi"

# -------------------------------
# SECTION 7 — GitHub CI/CD
# -------------------------------
$env:GITHUB_USERNAME = "RobelBT-FL"
$env:GITHUB_REPO     = "sentiment_classification_app_v1"
$env:SP_NAME         = "github-actions-sentiment-robel"

# -------------------------------
# SECTION 8 — Cost Alert
# -------------------------------
$env:ALERT_EMAIL   = "robelberhe09@gmail.com"
$env:BUDGET_AMOUNT = "10"

# -------------------------------
# SECTION 9 — Confirmation Output
# -------------------------------
Write-Host "Config loaded successfully!"
Write-Host "Resource Group: $env:RESOURCE_GROUP"
Write-Host "ACR Server:     $env:ACR_SERVER"
Write-Host "Backend Image:  $env:BACKEND_IMAGE"
Write-Host "Frontend Image: $env:FRONTEND_IMAGE"
Write-Host "Backend App:    $env:ACA_APP"
Write-Host "Frontend App:   $env:ACA_FRONTEND_APP"
Write-Host "Location:       $env:AZURE_LOCATION"



$env:BACKEND_URL = "https://sentiment-backend-api-app.nicedune-b5b33eb3.eastus2.azurecontainerapps.io"

# ============================================
# FRONTEND ENVIRONMENT VARIABLES
# ============================================

$env:NEXT_PUBLIC_API_URL = "https://sentiment-backend-api-app.nicedune-b5b33eb3.eastus2.azurecontainerapps.io"

$env:SP_NAME = "sentiment-cicd-sp"

