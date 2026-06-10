#!/bin/bash
# ^ This tells the system to run this file using the Bash shell.
#   Every Bash script should start with this line.

###############################################
# Azure Resource Group + ACR Setup Script
# Region: East US 2
# Author: Robel (with Copilot)
###############################################

# -------------------------------
# 1. Set the Azure region
# -------------------------------
# LOCATION is a variable that stores the Azure region where
# all resources will be created. "eastus2" = East US 2 (Virginia).
LOCATION="eastus2"

# -------------------------------
# 2. Set the Resource Group name
# -------------------------------
# RESOURCE_GROUP is the name of the Azure Resource Group.
# A Resource Group is a logical container for your resources.
RESOURCE_GROUP="sentimentmyresourcerroup"

# -------------------------------
# 3. Set the ACR (Azure Container Registry) name
# -------------------------------
# ACR names must be globally unique across all of Azure.
# $RANDOM adds a random number to avoid name conflicts.
ACR_NAME="sentimentmyacrregistry$RANDOM"

# -------------------------------
# 4. Create the Resource Group
# -------------------------------
# echo prints a message to the terminal so you know what’s happening.
echo "Creating Resource Group: $RESOURCE_GROUP in $LOCATION ..."

# az group create is the Azure CLI command to create a Resource Group.
# --name sets the name, --location sets the region.
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# -------------------------------
# 5. Create the Azure Container Registry (ACR)
# -------------------------------
echo "Creating Azure Container Registry: $ACR_NAME ..."

# az acr create creates a private Docker registry in Azure.
# --sku Standard is the recommended tier for most workloads.
az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME \
  --sku Standard \
  --location $LOCATION

# -------------------------------
# 6. Final output messages
# -------------------------------
echo "Done!"
echo "Resource Group created: $RESOURCE_GROUP"
echo "ACR created: $ACR_NAME"
echo "Region used: $LOCATION"
