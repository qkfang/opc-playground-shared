# opc-playground-shared

This repo contains the Bicep for the shared playground resource group.

The current deployment models:

- A primary Azure AI Services account in Australia East
- A secondary Azure AI Services account in East US 2
- Workspace-based Application Insights backed by Log Analytics
- A shared StorageV2 account with private blob containers `file-in` and `file-out`
- Diagnostic settings from both AI Services accounts into the shared workspace
