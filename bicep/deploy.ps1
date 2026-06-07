$resourceGroupName = 'rg-playground-shared'

az group create --name $resourceGroupName --location 'australiaeast'

az deployment group create --name 'playground-shared-deploy' --resource-group $resourceGroupName --template-file './main.bicep' --parameters './main.bicepparam' --query 'properties.outputs' -o json | ConvertFrom-Json
