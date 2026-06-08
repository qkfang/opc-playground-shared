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

@description('Principals to assign the Azure AI Developer role on this Foundry account.')
param principals array = []

@description('Deploy gpt-5.4 and text-embedding-3-large models.')
param deployModels bool = true

@description('Deploy Whisper model (Standard SKU, only available in northcentralus and southcentralus).')
param deployWhisper bool = false

// Azure AI Developer role
var azureAIDeveloperRoleId = '64702f94-c441-49e6-a78b-ef80e0188fee'

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
    customSubDomainName: aiServicesName
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
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
  properties: {
  }
}

resource gpt54Deployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = if (deployModels) {
  parent: foundry
  name: 'gpt-5.4'
  sku: {
    name: 'GlobalStandard'
    capacity: 200
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-5.4'
      version: '2026-03-05'
    }
  }
}

resource embeddingDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = if (deployModels) {
  parent: foundry
  name: 'text-embedding-3-large'
  dependsOn: [gpt54Deployment]
  sku: {
    name: 'GlobalStandard'
    capacity: 500
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'text-embedding-3-large'
    }
  }
}

resource whisperDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = if (deployWhisper) {
  parent: foundry
  name: 'whisper'
  sku: {
    name: 'Standard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'whisper'
      version: '001'
    }
  }
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

resource developerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principal in principals: {
  name: guid(foundry.id, principal.id, azureAIDeveloperRoleId)
  scope: foundry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', azureAIDeveloperRoleId)
    principalId: principal.id
    principalType: principal.principalType
  }
}]

output aiServicesId string = foundry.id
output aiServicesName string = foundry.name
output aiServicesEndpoint string = foundry.properties.endpoint
output aiHubPrincipalId string = foundry.identity.principalId
output aiProjectEndpoint string = aiProject.properties.endpoints['AI Foundry API']
output aiProjectPrincipalId string = aiProject.identity.principalId
