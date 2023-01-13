param location string 

param dbvnetv4AddressRange string
param VMSubnetv4AddressRange string
param AzureBastionSubnetv4AddressRange string
param publicSubnetv4AddressRange string
param privateSubnetv4AddressRange string
param privateEndpointSubnetv4AddressRange string

param storageaccountname string

param adminUsername string

param adminPassword string

param wsname string
param managedResourceGroupName string

var vmName = 'testvm'
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var imageSku = '2019-Datacenter'
var imageId = '/subscriptions/0245be41-c89b-4b46-a3cc-a705c90cd1e8/resourceGroups/image-gallery-rg/providers/Microsoft.Compute/galleries/mddimagegallery/images/windows2019-networktools/versions/2.0.0'

//var managedResourceGroupName = concat('databricks-rg-', clustername, '-', uniqueString(clustername), resourceGroup().id)
var managedResourceGroupId =  '${subscription().id}/resourceGroups/${managedResourceGroupName}'
//var managedResourceGroupId =  concat(subscription().id, '/resourceGroups/', managedResourceGroupName)
var tier = 'Premium'
var clustervnetname = 'clustervnet'
var vmsubnetname = 'vm-subnet'
var publicsubnetname = 'pub-subnet'
var privatesubnetname = 'prv-subnet'
var privateendpointsubnetname = 'pe-subnet'
var privateendpointname = '${wsname}-pe'

var privatednszonename = 'privatelink.azuredatabricks.net'
var privatednsgroupname = '${privateendpointname}/pdnsgrp'


//public IP prefixes
resource prefixIpV4 'Microsoft.Network/publicIPPrefixes@2020-11-01' = {
  name: 'prefixIpV4'
  location: location
  sku:{
    name: 'Standard'
    tier: 'Regional'
  }
  zones:[
    '1'
    '2'
    '3'
  ]
  properties: {
    prefixLength: 28
    publicIPAddressVersion: 'IPv4'
  }
}
// public IPs from prefixes
resource clusterBastionPubIpV4 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: 'clusterBastionPubIpV4'
  location: location
  sku:{
    name: 'Standard'
  }
  zones:[
    '1'
    '2'
    '3'
  ]
  properties:{
    publicIPAllocationMethod: 'Static' 
    publicIPAddressVersion: 'IPv4'
    publicIPPrefix: {
      id: prefixIpV4.id
    }
  }
}
resource vmPubIpV4 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: 'vmPubIpV4'
  location: location
  sku:{
    name: 'Standard'
  }
  zones:[
    '1'
    '2'
    '3'
  ]
  properties:{
    publicIPAllocationMethod: 'Static' 
    publicIPAddressVersion: 'IPv4'
    publicIPPrefix: {
      id: prefixIpV4.id
    }
  }
}
// VNET
resource clustervnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: clustervnetname
  location: location
  properties:{
    addressSpace:{
      addressPrefixes:[
        dbvnetv4AddressRange       
      ]
    }
    subnets:[
      {
      name: vmsubnetname
      properties:{
        addressPrefix:  VMSubnetv4AddressRange
        networkSecurityGroup: {
          id: nsg.id
        }
        
      }
    }     
    {
      name: 'AzureBastionSubnet'
      properties:{
        addressPrefix: AzureBastionSubnetv4AddressRange
      }
    }
    {
      name: publicsubnetname
      properties:{
        addressPrefix: publicSubnetv4AddressRange
        networkSecurityGroup: {
          id: nsg.id
        }
        delegations: [
          {
            name: 'databricks-del-${uniqueString(publicsubnetname)}'
            properties:{
              serviceName: 'Microsoft.Databricks/workspaces'
            }
          }
        ]
      }
    }
    {
      name: privatesubnetname
      properties:{
        addressPrefix: privateSubnetv4AddressRange
        networkSecurityGroup: {
          id: nsg.id
        }
        delegations: [
          {
            name: 'databricks-del-${uniqueString(privatesubnetname)}'
            properties:{
              serviceName: 'Microsoft.Databricks/workspaces'
            }
          }
        ]
      }
    }
    {
      name: privateendpointsubnetname
      properties:{
        addressPrefix: privateEndpointSubnetv4AddressRange
      }
    }
    ]
  }
}
//NSG
resource nsg 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: 'nsg'
  location: location
  properties:{
    securityRules: [
      {
        name: 'allow80in'
        properties:{
          priority: 150
          direction: 'Inbound'
          protocol: 'Tcp'
          access: 'Allow'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
          }
      }
      {
        name: 'allowRDPin'
        properties:{
          priority: 110
          direction: 'Inbound'
          protocol: 'Tcp'
          access: 'Allow'
          sourceAddressPrefix: '217.122.185.32'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
         }
        }
        {
         name: 'allowSSHin'
         properties:{
         priority: 120
         direction: 'Inbound'
         protocol: 'Tcp'
         access: 'Allow'
         sourceAddressPrefix: '217.122.185.32'
         sourcePortRange: '*'
         destinationAddressPrefix: '*'
         destinationPortRange: '22'
         }
        }
        {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-databricks-webapp'
        properties: {
          description: 'Required for workers communication with Databricks Webapp.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureDatabricks'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          }
        }
        {
          name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-sql'
          properties: {
            description: 'Required for workers communication with Azure SQL.'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '3306'
            sourceAddressPrefix: 'VirtualNetwork'
            destinationAddressPrefix: 'Sql'
            access: 'Allow'
            priority: 101
            direction: 'Outbound'
            sourcePortRanges: []
            destinationPortRanges: []
            sourceAddressPrefixes: []
            destinationAddressPrefixes: []
            }
          }
          {
            name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-storage'
            properties: {
              description: 'Required for workers communication with Azure Storage.'
              protocol: 'Tcp'
              sourcePortRange: '*'
              destinationPortRange: '443'
              sourceAddressPrefix: 'VirtualNetwork'
              destinationAddressPrefix: 'Storage'
              access: 'Allow'
              priority: 102
              direction: 'Outbound'
              sourcePortRanges: []
              destinationPortRanges: []
              sourceAddressPrefixes: []
              destinationAddressPrefixes: []
              }
            }
            {
              name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-eventhub'
              properties: {
                description: 'Required for workers communication with Azure Eventhub.'
                protocol: 'Tcp'
                sourcePortRange: '*'
                destinationPortRange: '9093'
                sourceAddressPrefix: 'VirtualNetwork'
                destinationAddressPrefix: 'EventHub'
                access: 'Allow'
                priority: 104
                direction: 'Outbound'
                sourcePortRanges: []
                destinationPortRanges: []
                sourceAddressPrefixes: []
                destinationAddressPrefixes: []
                }
            }
    ]
  }
}

//Bastion - remove comments to deploy Bastion, takes a while
resource hubBastion 'Microsoft.Network/bastionHosts@2021-08-01' = {
  name: 'clusterBastion'
  dependsOn:[
    clustervnet
    clusterBastionPubIpV4
  ]
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    enableFileCopy: true
    enableIpConnect: true
    enableShareableLink: true
    enableTunneling: true
    disableCopyPaste: false
    ipConfigurations: [
      {
        name: 'ipConf'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets',clustervnetname,'AzureBastionSubnet')
          } 
          publicIPAddress: {
            id: clusterBastionPubIpV4.id
          }
        }
      }
    ]
  }
}
//VM
resource vm 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile:{
      vmSize: 'Standard_DS2_v2'
    }
    storageProfile:  {
      imageReference: {
        //id: imageId
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'      
        }
      }
      osProfile:{
        computerName: vmName
        adminUsername: adminUsername
        adminPassword: adminPassword
      }
      networkProfile: {
        networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}
resource nic 'Microsoft.Network/networkInterfaces@2021-08-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      { 
        name: 'ipv4config0'
        properties:{
          primary: true
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddressVersion: 'IPv4'
          subnet :{
            id: resourceId('Microsoft.Network/virtualNetworks/subnets',clustervnetname,vmsubnetname)
          }
          publicIPAddress: {
            id: vmPubIpV4.id
          }
        }    
      }
     
    ]
  }
}
//databricksworkspace
resource dbws 'Microsoft.Databricks/workspaces@2021-04-01-preview' = {
  name: wsname
  location: location
  dependsOn:[
   clustervnet 
  ]
  sku: {
    name: tier
  }
  properties:{
    managedResourceGroupId: managedResourceGroupId
    parameters:{
      enableNoPublicIp: {
        value: true
      }
      customVirtualNetworkId: {
        value: clustervnet.id
      }
      customPublicSubnetName: {
        value: publicsubnetname
      }
      customPrivateSubnetName: {
        value: privatesubnetname
      }
    }
  }
}
// private dns zone
/*resource pednszone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privatednszonename
  location: location
  dependsOn:[
    pe
  ]
}
resource pednszonegroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01'= {
  name: privatednsgroupname
  properties:{
    privateDnsZoneConfigs:[
      {
        name: 'config1'
        properties:{
          privateDnsZoneId: pednszone.id
        }
      }
    ]
  }
}
resource pednszonelink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privatednszonename}/${privatednszonename}-link'
  dependsOn:[
    pednszone
    clustervnet
  ]
  properties:{
    registrationEnabled: false
    virtualNetwork:{
      id: clustervnet.id
    }
  }
}
//private endpoint to databricks ws
resource pe 'Microsoft.Network/privateEndpoints@2021-08-01'= {
  name: privateendpointname
  location: location
  dependsOn:[
    dbws
    clustervnet
  ]
  properties:{
    subnet:{
      id: resourceId('Microsoft.Network/virtualNetworks/subnets',clustervnetname,privateendpointsubnetname)
    }
    privateLinkServiceConnections:[
      {
        name: privateendpointname
        properties:{
          privateLinkServiceId: dbws.id
          groupIds:[
            'databricks_ui_api'
          ]
        }
      }
    ]
  }
}*/
//storage
resource storage 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageaccountname
  location: location
  kind:'StorageV2'
  sku: {
    name:'Standard_LRS'
  }
  properties:{
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
  }
}
output nsg object = nsg
output st object = storage

