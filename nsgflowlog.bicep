param location string 
param nsg object
param storage object

param workSpaceId string
param workSpaceRegion string
param workSpaceResourceId string

resource nsgflowlog 'Microsoft.Network/networkWatchers/flowLogs@2021-08-01' ={
    name: 'NetworkWatcher_westeurope/nsgflowlog'
    location: location

    properties:{
      targetResourceId: '/subscriptions/${nsg.subscriptionId}/resourcegroups/${nsg.resourceGroupName}/providers/${nsg.resourceId}'
      storageId: 'subscriptions/${storage.subscriptionId}/resourcegroups/${storage.resourceGroupName}/providers/${storage.resourceId}' 
      enabled: true
      format:{
        type: 'JSON'
        version: 2
      }
      flowAnalyticsConfiguration:{
        networkWatcherFlowAnalyticsConfiguration:{
          enabled: true
          workspaceId: workSpaceId
          workspaceRegion: workSpaceRegion
          workspaceResourceId: workSpaceResourceId
          trafficAnalyticsInterval: 60
        }
      }
    }
  }
