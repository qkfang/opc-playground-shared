@description('Azure region for the AI Services account.')
param location string

@description('AI Services account name.')
param aiServicesName string

@description('AI Foundry project name.')
param aiProjectName string

@description('SKU name for the AI Services account.')
param skuName string = 'S0'

@description('Optional Log Analytics workspace resource ID used for AI Services diagnostics.')
param logAnalyticsWorkspaceId string = ''

@description('Tags applied to the AI Services account.')
param tags object = {}

resource foundry 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: aiServicesName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: skuName
  }
  kind: 'AIServices'
  properties: {
    allowProjectManagement: true
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

resource aiProject 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  parent: foundry
  name: aiProjectName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}

resource aiHubDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: 'send-to-law'
  scope: foundry
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output aiServicesId string = foundry.id
output aiServicesName string = foundry.name
output aiServicesEndpoint string = foundry.properties.endpoint
output aiHubPrincipalId string = foundry.identity.principalId
output aiProjectEndpoint string = aiProject.properties.endpoints['AI Foundry API']
output aiProjectPrincipalId string = aiProject.identity.principalId
