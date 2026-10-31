#!/usr/bin/env bash
# Azure Bicep Infrastructure Deployment Automation Script
set -e

RESOURCE_GROUP=${1:-"rg-devops-cloud-prod"}
LOCATION=${2:-"eastus"}
ENVIRONMENT=${3:-"dev"}

echo "☁️ Azure Bicep Infrastructure Deployment"
echo "Resource Group: $RESOURCE_GROUP | Region: $LOCATION | Env: $ENVIRONMENT"

# 1. Check Azure Login
if ! az account show > /dev/null 2>&1; then
    echo "⚠️ Please login to Azure CLI first..."
    az login
fi

# 2. Create Resource Group if not exists
echo "Creating/Verifying Resource Group..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output table

# 3. Validate Template
echo "Validating Bicep Template..."
az deployment group validate \
    --resource-group "$RESOURCE_GROUP" \
    --template-file main.bicep \
    --parameters environmentName="$ENVIRONMENT"

# 4. What-If Analysis
echo "Running What-If Speculation..."
az deployment group what-if \
    --resource-group "$RESOURCE_GROUP" \
    --template-file main.bicep \
    --parameters environmentName="$ENVIRONMENT"

# 5. Deploy
read -p "Proceed with deployment? [y/N]: " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    DEPLOYMENT_NAME="deploy-$(date +%s)"
    echo "Deploying $DEPLOYMENT_NAME..."
    az deployment group create \
        --name "$DEPLOYMENT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --template-file main.bicep \
        --parameters environmentName="$ENVIRONMENT"
    echo "✅ Deployment Succeeded!"
fi
