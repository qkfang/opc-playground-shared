targetScope = 'resourceGroup'

@description('Primary region for shared monitoring and the primary AI Services account.')
param primaryLocation string = resourceGroup().location

@description('Secondary region for the paired AI Services account.')
param secondaryLocation string = 'eastus2'

@description('Primary Azure AI Services account name.')
param primaryAiServicesName string = 'play-foundry'

@description('Secondary Azure AI Services account name.')
param secondaryAiServicesName string = 'play-foundry-eastus2'

@description('Log Analytics workspace name used by Application Insights and diagnostics.')
param logAnalyticsName string = 'play-shared-law'

@description('Workspace-based Application Insights name for the shared environment.')
param appInsightsName string = 'play-shared-appi'

@description('Tags applied to all managed resources.')
param tags object = {
  project: 'opc-playground-shared'
  environment: 'shared'
}

module monitoring 'monitoring.bicep' = {
  name: 'monitoring'
  params: {
    location: primaryLocation
    logAnalyticsName: logAnalyticsName
    appInsightsName: appInsightsName
    tags: tags
  }
}

module primaryFoundry 'foundry.bicep' = {
  name: 'primary-foundry'
  params: {
    location: primaryLocation
    aiServicesName: primaryAiServicesName
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsId
    tags: tags
  }
}

module secondaryFoundry 'foundry.bicep' = {
  name: 'secondary-foundry'
  params: {
    location: secondaryLocation
    aiServicesName: secondaryAiServicesName
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsId
    tags: union(tags, {
      failover: 'true'
    })
  }
}

output primaryAiServicesId string = primaryFoundry.outputs.aiServicesId
output primaryAiServicesEndpoint string = primaryFoundry.outputs.aiServicesEndpoint
output secondaryAiServicesId string = secondaryFoundry.outputs.aiServicesId
output secondaryAiServicesEndpoint string = secondaryFoundry.outputs.aiServicesEndpoint
output appInsightsConnectionString string = monitoring.outputs.appInsightsConnectionString
output logAnalyticsWorkspaceId string = monitoring.outputs.logAnalyticsId
