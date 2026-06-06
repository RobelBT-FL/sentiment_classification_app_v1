# Azure Deployment Scripts — LLaMA 2 13B Sentiment API

## 📋 Overview

These bash scripts deploy your FastAPI + LLaMA 2 13B backend to Azure Container Apps.
Run them in order — once. After that, every `git push` triggers CI/CD automatically.

## 🗂️ Scripts

| Script | What it does | Run |
|--------|-------------|-----|
| `00-config.sh` | **Edit this first.** All config variables in one place. | `source 00-config.sh` |
| `01-azure-setup.sh` | Creates Resource Group, ACR, Blob Storage, ACA Environment | Once |
| `02-upload-model.sh` | Uploads your 9 GB GGUF model to private Azure Blob | Once (slow) |
| `03-build-push.sh` | Builds Dockerfile.azure → pushes to ACR | First deploy (then CI/CD) |
| `04-deploy.sh` | Creates or updates Azure Container App | First deploy (then CI/CD) |
| `05-github-cicd-setup.sh` | Creates Service Principal, writes GitHub Actions workflow | Once |
| `06-ops.sh` | Day-to-day: logs, status, rollback, scale, teardown | Anytime |
| `Dockerfile.azure` | Azure-specific Dockerfile (port 8080, model from Blob) | Copy to backend/ |

## 🚀 Quick Start

```bash
# Step 0: Edit config
nano 00-config.sh   # Set your subscription ID, ACR name, storage name, model path

# Step 1: One-time Azure infrastructure setup
bash 01-azure-setup.sh

# Step 2: Upload your model (runs in background — 30-60 mins)
bash 02-upload-model.sh &

# Step 3: Build and push Docker image (while model uploads)
bash 03-build-push.sh

# Step 4: Deploy to Azure Container Apps
bash 04-deploy.sh

# Step 5: Set up GitHub Actions CI/CD (one time)
bash 05-github-cicd-setup.sh

# Add the printed GitHub Secrets, then push:
git add .github/ Dockerfile.azure
git commit -m "Add Azure CI/CD pipeline"
git push origin main
```

## 📅 Daily Operations

```bash
bash 06-ops.sh logs        # Stream live logs
bash 06-ops.sh status      # Show URL + status
bash 06-ops.sh revisions   # See all deployments
bash 06-ops.sh rollback    # Roll back to previous version
bash 06-ops.sh scale-zero  # Save money (scale to 0)
bash 06-ops.sh scale-warm  # Remove cold starts (min 1 replica)
bash 06-ops.sh cost        # Estimate monthly cost
bash 06-ops.sh teardown    # ⚠️ Delete everything
```

## ⚠️ Prerequisites

- Azure CLI installed: `az --version`
- Docker Desktop running: `docker info`
- WSL or Git Bash on Windows (these are bash scripts)
- Azure subscription with billing enabled
- Logged in: `az login`

## 📁 Where to put Dockerfile.azure

Copy `Dockerfile.azure` to your `backend/` folder (same level as your existing `Dockerfile`).

```
backend/
├── Dockerfile           ← local dev (unchanged)
├── Dockerfile.azure     ← Azure deployment (copy here)
├── docker-compose.yml   ← local dev (unchanged)
├── requirements.txt
└── src/
```

## 💰 Cost Summary

| Scenario | Monthly Cost |
|----------|-------------|
| Demo/portfolio (scale-to-zero) | ~$20-25 |
| Moderate use (4 hrs/day) | ~$57 |
| Always-warm (min-replicas=1) | ~$316 |
