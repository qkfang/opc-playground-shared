
az group create --name 'rg-playground-shared' --location 'australiaeast'

az deployment group create --name 'playground-shared-deploy' --resource-group 'rg-playground-shared' --template-file './main.bicep' --parameters './main.bicepparam' --query 'properties.outputs' -o json | ConvertFrom-Json
