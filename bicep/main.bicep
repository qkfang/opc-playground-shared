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
  project: projectName
}

var logAnalyticsName = '${baseName}-law'
var appInsightsName = '${baseName}-appi'
var foundryName = '${baseName}-foundry'
var foundryUSName = '${baseName}-foundry-us'

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

module foundry 'foundry.bicep' = {
  name: 'foundry'
  params: {
    location: location
    aiServicesName: foundryName
    logAnalyticsWorkspaceId: logAnalytics.id
    tags: tags
  }
}

module foundryUS 'foundry.bicep' = {
  name: 'foundryUS'
  params: {
    location: 'eastus2'
    aiServicesName: foundryUSName
    logAnalyticsWorkspaceId: logAnalytics.id
    tags: union(tags, {
      failover: 'true'
    })
  }
}

output primaryAiServicesId string = foundry.outputs.aiServicesId
output primaryAiServicesEndpoint string = foundry.outputs.aiServicesEndpoint
output secondaryAiServicesId string = foundryUS.outputs.aiServicesId
output secondaryAiServicesEndpoint string = foundryUS.outputs.aiServicesEndpoint
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output logAnalyticsWorkspaceId string = logAnalytics.id
output principalsConfigured array = principals
