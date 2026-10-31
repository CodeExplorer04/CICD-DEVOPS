# ☁️ Azure CI/CD & DevOps Infrastructure as Code (Bicep)

> **Automated Cloud Infrastructure Deployment on Microsoft Azure using Bicep & CI/CD Pipelines**

[![Azure](https://img.shields.io/badge/Cloud-Microsoft%20Azure-0078D4?style=flat&logo=microsoftazure&logoColor=white)](https://azure.microsoft.com/)
[![Bicep](https://img.shields.io/badge/IaC-Azure%20Bicep-0078D4?style=flat&logo=azuredevops&logoColor=white)](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
[![DevOps](https://img.shields.io/badge/DevOps-CI%2FCD%20Ready-2088FF?style=flat&logo=githubactions&logoColor=white)](https://github.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 📌 Overview

This project showcases **Infrastructure as Code (IaC)** on **Microsoft Azure** using **Bicep**—Azure's next-generation declarative language for provisioning cloud resources cleanly, deterministically, and repeatably.

The template defines enterprise-standard cloud resources (such as secure Azure Storage Accounts) ready to be integrated into automated **GitHub Actions** or **Azure DevOps Pipelines** for continuous delivery and compliance validation.

---

## 🏗️ Repository Structure

```
CICD-DEVOPS/
├── main.bicep               # Declarative Azure Bicep resource definition
├── .gitignore               # Ignored build artifacts, credentials & local files
└── README.md                # Project documentation and deployment guide
```

---

## ⚙️ Resource Specifications (`main.bicep`)

The Bicep template provisions the following Azure resources:

| Property | Value | Description |
| :--- | :--- | :--- |
| **Resource Type** | `Microsoft.Storage/storageAccounts` | Azure Blob, File, Queue, and Table storage |
| **API Version** | `2023-05-01` | Modern Azure Resource Manager API specification |
| **Resource Name** | `demostorageaccount123` | Unique storage account identifier |
| **SKU** | `Standard_LRS` | Standard redundancy (Locally-Redundant Storage) |
| **Kind** | `StorageV2` | General Purpose v2 (supports blobs, data lakes, tiering) |
| **Location** | `resourceGroup().location` | Dynamically inherits parent Azure Resource Group region |

---

## 🛠️ Prerequisites

- **Azure Account:** Active Azure subscription ([Free Account](https://azure.microsoft.com/free/))
- **Azure CLI:** Version 2.40.0+ installed (`az --version`)
- **Bicep CLI:** Installed automatically with Azure CLI (`az bicep version`)
- **VS Code Extension (Recommended):** [Azure Bicep Extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep) for syntax highlighting and linting.

---

## 🚀 Deployment Guide

### Step 1: Log in to Azure
```bash
az login
```

### Step 2: Set Your Target Subscription
```bash
az account set --subscription "<Your-Subscription-Name-or-ID>"
```

### Step 3: Create an Azure Resource Group
```bash
az group create \
  --name "rg-devops-demo" \
  --location "eastus"
```

### Step 4: Validate & Lint the Bicep Template
Run a pre-flight validation check before making any cloud changes:
```bash
az deployment group validate \
  --resource-group "rg-devops-demo" \
  --template-file main.bicep
```

### Step 5: Preview with "What-If" Analysis
Inspect exact resource changes before applying:
```bash
az deployment group what-if \
  --resource-group "rg-devops-demo" \
  --template-file main.bicep
```

### Step 6: Deploy Resources
```bash
az deployment group create \
  --resource-group "rg-devops-demo" \
  --template-file main.bicep \
  --name "storageDeployment-$(date +%s)"
```

---

## 🔄 CI/CD Pipeline Automation (GitHub Actions Example)

To automate deployments on every `git push` to `main`, place the following workflow in `.github/workflows/deploy.yml`:

```yaml
name: Deploy Azure Bicep IaC

on:
  push:
    branches: [ main ]
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

jobs:
  validate-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Azure Login (OIDC / Service Principal)
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Validate Bicep Template
        uses: azure/arm-deploy@v2
        with:
          scope: resourcegroup
          resourceGroupName: rg-devops-demo
          template: ./main.bicep
          deploymentMode: Validate

      - name: Deploy Infrastructure
        uses: azure/arm-deploy@v2
        with:
          scope: resourcegroup
          resourceGroupName: rg-devops-demo
          template: ./main.bicep
          deploymentMode: Incremental
```

---

## 🔒 Security Best Practices

1. **Storage Account Naming:** Storage account names must be globally unique across all Azure accounts (3-24 characters, lowercase alphanumeric only).
2. **Access Control:** Integrate with Azure Key Vault to store secrets and use Managed Identities rather than static connection strings.
3. **Network Rules:** Configure private endpoints and restrict public network access for production environments.

---

## 📄 License

This project is open-source under the [MIT License](LICENSE).
