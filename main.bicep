@description('Environment prefix (e.g. dev, staging, prod)')
param environmentName string = 'prod'

@description('Primary deployment Azure region')
param location string = resourceGroup().location

@description('Globally unique suffix for Azure resource naming')
param uniqueSuffix string = uniqueString(resourceGroup().id)

@description('Storage Account SKU tier')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
])
param storageSku string = 'Standard_LRS'

// 1. Centralized Log Analytics Workspace for Observability
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'log-devops-${environmentName}-${uniqueSuffix}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// 2. Application Insights for Telemetry and Diagnostics
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-devops-${environmentName}-${uniqueSuffix}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

// 3. Azure Storage Account with Enterprise Security Baseline
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: take('st${environmentName}${uniqueSuffix}', 24)
  location: location
  sku: {
    name: storageSku
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    accessTier: 'Hot'
    encryption: {
      services: {
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

// Blob Services & Automated Containers
resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource assetsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobServices
  name: 'app-assets'
  properties: {
    publicAccess: 'None'
  }
}

// 4. Linux App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: 'asp-devops-${environmentName}-${uniqueSuffix}'
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// 5. Cloud Web Application
resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: 'app-devops-${environmentName}-${uniqueSuffix}'
  location: location
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.11'
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'STORAGE_ACCOUNT_NAME'
          value: storageAccount.name
        }
        {
          name: 'ENVIRONMENT'
          value: environmentName
        }
      ]
    }
  }
}

// Deployment Outputs
output storageAccountName string = storageAccount.name
output primaryBlobEndpoint string = storageAccount.properties.primaryEndpoints.blob
output webAppHostName string = webApp.properties.defaultHostName
output appInsightsConnectionString string = appInsights.properties.ConnectionString
