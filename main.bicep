param rgName string = 'databricks-lab-${utcNow()}'
param flowlogrgName string = 'NetworkWatcherRG'

param location string = 'westeurope'

param dbvnetv4AddressRange string = '10.0.0.0/16'
param VMSubnetv4AddressRange string = '10.0.0.0/24'
param AzureBastionSubnetv4AddressRange string = '10.0.1.0/24'
param publicSubnetv4AddressRange string = '10.0.10.0/24'
param privateSubnetv4AddressRange string = '10.0.11.0/24'
param privateEndpointSubnetv4AddressRange string = '10.0.20.0/24'

param wsname string = 'dbws'
param managedResourceGroupName string = 'databricks-rg-${wsname}-${uniqueString(rgName)}'

param storagePrefix string = 'bootst'

param adminUsername string = 'AzureAdmin'

param adminPassword string = 'Databricks-2022'

param storageaccountname string = '${storagePrefix}${uniqueString(rgName)}'

param workSpaceId string = '915c4396-965d-4b9c-821f-182a27260c8a'
param workSpaceRegion string = 'westeurope'
param workSpaceResourceId string = '/subscriptions/7749fbb8-4096-4e85-8ad2-ef8182d01f02/resourceGroups/laworkspace-rg/providers/Microsoft.OperationalInsights/workspaces/ext1-la-workspace-we'

targetScope = 'subscription'
 
resource dbRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
}

resource flowlogRg 'Microsoft.Resources/resourceGroups@2021-04-01' existing ={
  name: flowlogrgName
}

module dblab 'dblab.bicep' = {
name: 'dblab'
scope: dbRg
params: {
  location: location
  dbvnetv4AddressRange: dbvnetv4AddressRange
  VMSubnetv4AddressRange: VMSubnetv4AddressRange
  AzureBastionSubnetv4AddressRange: AzureBastionSubnetv4AddressRange
  publicSubnetv4AddressRange: publicSubnetv4AddressRange
  privateSubnetv4AddressRange: privateSubnetv4AddressRange
  privateEndpointSubnetv4AddressRange: privateEndpointSubnetv4AddressRange
  wsname: wsname
  managedResourceGroupName: managedResourceGroupName
  storageaccountname: storageaccountname

  adminUsername: adminUsername
  adminPassword: adminPassword

  }
}

module nsgflowlog 'nsgflowlog.bicep' = {
  name: 'nsgflowlog'
  scope: flowlogRg
  dependsOn:[
    dblab
  ]
  params:{
    location: location
    nsg: dblab.outputs.nsg
    storage: dblab.outputs.st

    workSpaceId: workSpaceId
    workSpaceRegion: workSpaceRegion
    workSpaceResourceId: workSpaceResourceId



  }
}
