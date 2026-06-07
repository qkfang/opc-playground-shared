using 'main.bicep'

param primaryLocation = 'australiaeast'
param secondaryLocation = 'eastus2'
param primaryAiServicesName = 'play-foundry'
param secondaryAiServicesName = 'play-foundry-eastus2'
param logAnalyticsName = 'play-shared-law'
param appInsightsName = 'play-shared-appi'
param tags = {
  project: 'opc-playground-shared'
  environment: 'shared'
}

