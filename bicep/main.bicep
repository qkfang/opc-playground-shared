targetScope = 'resourceGroup'

@description('Primary region for shared monitoring and the primary AI Services account.')
param location string = resourceGroup().location

@description('Project base name used to derive resource names.')
param baseName string

@description('Project name used in resource tags.')
param projectName string

@description('Additional principals reserved for role assignments.')
param principals array = []

var tags = {
  SecurityControl: 'Ignore'
}

var logAnalyticsName = '${baseName}-law'
var appInsightsName = '${baseName}-appi'
var foundryName = '${baseName}-foundry'
var foundryUSName = '${baseName}-foundry-us'
var foundryProjectName = '${baseName}-project'
var foundryUSProjectName = '${baseName}-project-us'
var storageAccountName = take(toLower('${baseName}st${uniqueString(resourceGroup().id)}'), 24)
var blobContainerNames = [
  'file-in'
  'file-out'
]

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
}

resource blobContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = [for containerName in blobContainerNames: {
  parent: blobService
  name: containerName
  properties: {
    publicAccess: 'None'
  }
}]

module foundry 'foundry.bicep' = {
  name: 'foundry'
  params: {
    location: location
    aiServicesName: foundryName
    aiProjectName: foundryProjectName
    logAnalyticsWorkspaceId: logAnalytics.id
    tags: tags
    principals: principals
  }
}

module foundryUS 'foundry.bicep' = {
  name: 'foundryUS'
  params: {
    location: 'eastus2'
    aiServicesName: foundryUSName
    aiProjectName: foundryUSProjectName
    logAnalyticsWorkspaceId: logAnalytics.id
    tags: union(tags, {
      failover: 'true'
    })
    principals: principals
  }
}

