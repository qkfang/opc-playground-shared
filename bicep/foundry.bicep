@description('Azure region for the AI Services account.')
param location string

@description('AI Services account name.')
param aiServicesName string

@description('SKU name for the AI Services account.')
param skuName string = 'S0'

@description('Optional Log Analytics workspace resource ID used for AI Services diagnostics.')
param logAnalyticsWorkspaceId string = ''

@description('Tags applied to the AI Services account.')
param tags object = {}

resource aiHub 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
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

resource aiHubDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: 'send-to-law'
  scope: aiHub
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

output aiServicesId string = aiHub.id
output aiServicesName string = aiHub.name
output aiServicesEndpoint string = aiHub.properties.endpoint
output aiHubPrincipalId string = aiHub.identity.principalId
