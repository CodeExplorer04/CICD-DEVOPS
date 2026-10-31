<#
.SYNOPSIS
    Automated Azure Infrastructure Provisioning via Bicep
.DESCRIPTION
    Validates, previews (what-if), and deploys Azure resources defined in main.bicep.
#>

param (
    [string]$ResourceGroupName = "rg-devops-cloud-prod",
    [string]$Location = "eastus",
    [string]$Environment = "dev"
)

Write-Host "☁️ Azure Bicep Deployment Engine" -ForegroundColor Cyan
Write-Host "Target Resource Group: $ResourceGroupName ($Location)"
Write-Host "Environment: $Environment`n"

# Verify Azure CLI login
$account = az account show --output json 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Warning "Not logged in to Azure CLI. Running 'az login'..."
    az login
}

# Ensure target Resource Group exists
Write-Host "🔍 Ensuring Resource Group '$ResourceGroupName' exists..." -ForegroundColor Yellow
az group create --name $ResourceGroupName --location $Location --output table

# Validate Bicep template
Write-Host "`n🧪 Validating Bicep template syntax and parameters..." -ForegroundColor Yellow
az deployment group validate `
    --resource-group $ResourceGroupName `
    --template-file main.bicep `
    --parameters environmentName=$Environment `
    --output table

# Run What-If speculative preview
Write-Host "`n🔎 Performing Speculative What-If analysis..." -ForegroundColor Yellow
az deployment group what-if `
    --resource-group $ResourceGroupName `
    --template-file main.bicep `
    --parameters environmentName=$Environment

# Prompt before deploying
$confirmation = Read-Host "`nProceed with deployment to Azure? (y/n)"
if ($confirmation -match "^[yY]$") {
    $deploymentName = "deploy-bicep-$Environment-$((Get-Date).ToString('yyyyMMdd-HHmmss'))"
    Write-Host "`n🚀 Deploying resources ($deploymentName)..." -ForegroundColor Green

    az deployment group create `
        --name $deploymentName `
        --resource-group $ResourceGroupName `
        --template-file main.bicep `
        --parameters environmentName=$Environment `
        --output table

    Write-Host "`n✅ Azure Deployment Completed Successfully!" -ForegroundColor Green
} else {
    Write-Host "`nDeployment cancelled by user." -ForegroundColor Gray
}
