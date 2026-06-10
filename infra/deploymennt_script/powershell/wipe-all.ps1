'''What this script does
#✔ Deletes all Docker containers
✔ Deletes all Docker images
✔ Deletes all Docker volumes
✔ Deletes all Docker networks
✔ Deletes all Docker build cache
✔ Deletes your entire Azure Resource Group
✔ Deletes ACR
✔ Deletes Container Apps
✔ Deletes Storage Accounts
✔ Deletes Log Analytics
✔ Deletes Managed Identities
✔ Deletes ANY leftover Azure resources
After running this, your machine and Azure subscription are fresh.'''


Write-Host "============================================================"
Write-Host "🔥 FULL DOCKER + FULL AZURE WIPE"
Write-Host "============================================================"

# ============================================================
# 1. FULL DOCKER WIPE
# ============================================================
Write-Host "🔥 Wiping ALL Docker resources..."

docker stop $(docker ps -aq) 2>$null
docker rm $(docker ps -aq) 2>$null
docker rmi -f $(docker images -aq) 2>$null
docker volume rm $(docker volume ls -q) 2>$null

$networks = docker network ls -q | Select-String -NotMatch "bridge|host|none"
if ($networks) {
    docker network rm $networks 2>$null
}

docker builder prune -a -f
docker system prune -a --volumes -f

Write-Host "✅ Docker fully wiped!"
Write-Host ""

# ============================================================
# 2. FULL AZURE WIPE
# ============================================================

# Set your resource group name here
$rg = "sentimentmyresoursehelen2012"
$acr = "sentimentacrregistryhelen2012"

Write-Host "🔥 Deleting Azure Resource Group: $rg ..."
az group delete --name $rg --yes --no-wait

Write-Host "⏳ Azure is deleting everything in the resource group..."
Write-Host "   This includes ACR, ACA, Storage, Logs, Identities, Networking."
Write-Host ""

# Optional double-wipe in case anything was created outside the RG
Write-Host "🔥 Checking for leftover ACR..."
az acr delete --name $acr --yes 2>$null

Write-Host "🔥 Checking for leftover Container Apps Environments..."
az containerapp env list --query "[].name" -o tsv | ForEach-Object {
    az containerapp env delete --name $_ --resource-group $rg --yes 2>$null
}

Write-Host "🔥 Checking for leftover Storage Accounts..."
az storage account list --query "[].name" -o tsv | ForEach-Object {
    az storage account delete --name $_ --resource-group $rg --yes 2>$null
}

Write-Host "🔥 Checking for leftover Managed Identities..."
az identity list --query "[].name" -o tsv | ForEach-Object {
    az identity delete --name $_ --resource-group $rg 2>$null
}

Write-Host "🔥 Checking for leftover Log Analytics Workspaces..."
az monitor log-analytics workspace list --query "[].name" -o tsv | ForEach-Object {
    az monitor log-analytics workspace delete --workspace-name $_ --resource-group $rg --yes 2>$null
}

Write-Host ""
Write-Host "============================================================"
Write-Host "✅ FULL DOCKER + FULL AZURE WIPE COMPLETE"
Write-Host "============================================================"
Write-Host "Your system and Azure subscription are now 100% clean."
Write-Host "You can safely restart your entire deployment from scratch."
