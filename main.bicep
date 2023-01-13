param location string = 'westeurope'

param adminUsername string
@secure()
param adminpassword string
param keyData string
@secure()
param privateKeyData string
param userID string

module logAnalyticsWorkspace '../ResourceModules/modules/Microsoft.OperationalInsights/workspaces/deploy.bicep' = {
  name: '${uniqueString(deployment().name)}-logAnalytics-Workspace'
  params: {
    // Required parameters
    name: 'loganalytics'
    location: location
  }
}

module nsgBastionSubnet '../ResourceModules/modules/Microsoft.Network/networkSecurityGroups/deploy.bicep' = {
  name: '${uniqueString(deployment().name)}-nsg-hubbastion'
  params: {
    // Required parameters
    name: 'nsg-hub-bastion-subnet'
    location: location
    // Non-required parameters
    diagnosticLogsRetentionInDays: 7
    diagnosticWorkspaceId: logAnalyticsWorkspace.outputs.resourceId
    securityRules: [
      {
        name: 'AllowHTTPSInbound'
        properties: {
          access: 'Allow'
          description: 'Allow incoming HTTPS'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          direction: 'Inbound'
          priority: 120
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowGatewayManagerInbound'
        properties: {
          access: 'Allow'
          description: 'Allow incoming HTTPS from Gateway Manager'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          direction: 'Inbound'
          priority: 130
          protocol: 'Tcp'
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowLoadBalancerInbound'
        properties: {
          access: 'Allow'
          description: 'Allow incoming HTTPS from Load Balancer'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          direction: 'Inbound'
          priority: 140
          protocol: 'Tcp'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowBastionHostCommunication'
        properties: {
          access: 'Allow'
          description: 'Allow data plane communication between the underlying components of Azure Bastion'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          direction: 'Inbound'
          priority: 150
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowSshRdpOutbound'
        properties: {
          access: 'Allow'
          description: 'Allow connection from Azure Bastion to target VMs'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '22'
            '3389'
          ]
          direction: 'Outbound'
          priority: 100
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowTunnelOutbound'
        properties: {
          access: 'Allow'
          description: 'Allow connection from Azure Bastion to target VMs for tunneling purpose'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '80'
          direction: 'Outbound'
          priority: 105
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowAzureCloudOutbound'
        properties: {
          access: 'Allow'
          description: 'Allow data plane communication between the underlying components of Azure Bastion'
          destinationAddressPrefix: 'AzureCloud'
          destinationPortRange: '443'
          direction: 'Outbound'
          priority: 110
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowBastionCommunication'
        properties: {
          access: 'Allow'
          description: 'Allow data plane communication between the underlying components of Azure Bastion'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          direction: 'Outbound'
          priority: 120
          protocol: 'Tcp'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowGetSessionInformationOutbound'
        properties: {
          access: 'Allow'
          description: 'Allow CRL checks and session information from Azure Bastion'
          destinationAddressPrefix: 'Internet'
          destinationPortRange: '80'
          direction: 'Outbound'
          priority: 130
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
    ]
  }
}

module vnethub 'br/public:network/virtual-network:1.1.1' = {
  name: '${uniqueString(deployment().name)}-vnethub'
  params: {
    name: 'vnet-hub'
    location: location
    addressPrefixes: [
      '10.255.0.0/16'
    ]
    subnets: [
      {
        name: 'GatewaySubnet'
        addressPrefix: '10.255.255.0/24'
      }
      {
        name: 'AzureBastionSubnet'
        addressPrefix: '10.255.254.0/26'
        networkSecurityGroupId: nsgBastionSubnet.outputs.resourceId
      }
      {
        name: 'vnet-hub-subnet-shared'
        addressPrefix: '10.255.0.0/24'
      }
    ]
  }
}

module nsgproject1Subnet '../ResourceModules/modules/Microsoft.Network/networkSecurityGroups/deploy.bicep' = {
  name: '${uniqueString(deployment().name)}-nsgspokeproject1'
  params: {
    // Required parameters
    name: 'nsg-spoke-project1-subnet'
    location: location
    // Non-required parameters
    diagnosticLogsRetentionInDays: 7
    diagnosticWorkspaceId: logAnalyticsWorkspace.outputs.resourceId
    securityRules: [
      {
        name: 'AllowBastionInbound'
        properties: {
          access: 'Allow'
          description: 'Allow incoming traffic from Bastion'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          direction: 'Inbound'
          priority: 100
          protocol: 'Tcp'
          sourceAddressPrefix: '10.255.254.0/26'
          sourcePortRange: '*'
        }
      }
    ]
  }
}

module vnetspoke 'br/public:network/virtual-network:1.1.1' = {
  name: '${uniqueString(deployment().name)}-vnetspoke'
  params: {
    name: 'vnet-spoke1'
    location: location
    addressPrefixes: [
      '10.1.0.0/16'
    ]

    subnets: [
      {
        name: 'project1'
        addressPrefix: '10.1.0.0/24'
      }
    ]

    virtualNetworkPeerings: [
      {
        remoteVirtualNetworkId: vnethub.outputs.resourceId
        allowForwardedTraffic: true
        allowGatewayTransit: false
        allowVirtualNetworkAccess: true
        useRemoteGateways: false
        remotePeeringEnabled: true
        remotePeeringName: 'hub-spoke1'
        remotePeeringAllowVirtualNetworkAccess: true
        remotePeeringAllowForwardedTraffic: true
        remotePeeringUseRemoteGateways: false
      }
    ]
  }
}

module nsgFlowLogsSA '../ResourceModules/modules/Microsoft.Storage/storageAccounts/deploy.bicep' = {
  name: '${uniqueString(deployment().name)}-sa'
  params: {
    // Required parameters
    name: 'nsgflowlogsbastiondemosa'
    location: location
    // Non-required parameters
    allowBlobPublicAccess: false
    storageAccountSku: 'Standard_LRS'
    storageAccountKind: 'StorageV2'
  }
}

module networkWatcher '../ResourceModules/modules/Microsoft.Network/networkWatchers/deploy.bicep' = {
  name: '${uniqueString(deployment().name)}-networkWatcher'
  params: {
    flowLogs: [
      {
        storageId: nsgFlowLogsSA.outputs.resourceId
        targetResourceId: nsgBastionSubnet.outputs.resourceId
        trafficAnalyticsInterval: 10
        workspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
      }
      {
        storageId: nsgFlowLogsSA.outputs.resourceId
        targetResourceId: nsgproject1Subnet.outputs.resourceId
        trafficAnalyticsInterval: 10
        workspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
      }
    ]
    location: location
  }
}

module bastion '../ResourceModules/modules/Microsoft.Network/bastionHosts/deploy.bicep' = {
  name: '${uniqueString(deployment().name)}-bastionhost'
  params: {
    // Required parameters
    name: 'bastion-host'
    vNetId: vnethub.outputs.resourceId
    location: location
    // Non-required parameters
    diagnosticLogsRetentionInDays: 7
    diagnosticWorkspaceId: logAnalyticsWorkspace.outputs.resourceId
    disableCopyPaste: false
    enableFileCopy: true
    enableIpConnect: true
    enableShareableLink: true
    scaleUnits: 2
    skuType: 'Standard'
  }
}

module vmwindows '../ResourceModules/modules/Microsoft.Compute/virtualMachines/deploy.bicep' = {
  name: '${uniqueString(deployment().name)}-vmwindows'
  params: {
    name: 'win01'
    location: location
    adminUsername: adminUsername
    adminPassword: adminpassword
    imageReference: {
      offer: 'WindowsServer'
      publisher: 'MicrosoftWindowsServer'
      sku: '2022-datacenter'
      version: 'latest'
    }
    nicConfigurations: [
      {
        deleteOption: 'Delete'
        enableAcceleratedNetworking: false
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: vnetspoke.outputs.subnetResourceIds[0]
            networkSecurityGroupId: nsgproject1Subnet.outputs.resourceId
          }
        ]
        nicSuffix: '-nic-01'
      }
    ]
    osDisk: {
      caching: 'None'
      createOption: 'fromImage'
      deleteOption: 'Delete'
      diskSizeGB: '128'
      managedDisk: {
        storageAccountType: 'Standard_LRS'
      }
    }
    osType: 'Windows'
    vmSize: 'Standard_B2ms'
    encryptionAtHost: false
  }
}

module vmlinux '../ResourceModules/modules/Microsoft.Compute/virtualMachines/deploy.bicep' = {
  name: '${uniqueString(deployment().name)}-vmlinux'
  params: {
    adminUsername: adminUsername
    imageReference: {
      offer: '0001-com-ubuntu-server-jammy'
      publisher: 'Canonical'
      sku: '22_04-lts-gen2'
      version: 'latest'
    }
    nicConfigurations: [
      {
        deleteOption: 'Delete'
        enableAcceleratedNetworking: false
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: vnetspoke.outputs.subnetResourceIds[0]
          }
        ]
        nicSuffix: '-nic-01'
      }
    ]
    osDisk: {
      caching: 'None'
      createOption: 'fromImage'
      deleteOption: 'Delete'
      diskSizeGB: '128'
      managedDisk: {
        storageAccountType: 'Standard_LRS'
      }
    }
    osType: 'Linux'
    vmSize: 'Standard_B2ms'
    encryptionAtHost: false
    // Non-required parameters
    location: location
    name: 'ubuntu01'
    disablePasswordAuthentication: true
    publicKeys: [
      {
        keyData: keyData
        path: '/home/${adminUsername}/.ssh/authorized_keys'
      }
    ]
  }
}

module vaults '../ResourceModules/modules/Microsoft.KeyVault/vaults/deploy.bicep' = {
  name: '${uniqueString(deployment().name)}-kv'
  params: {
    name: 'kv-${uniqueString(deployment().name)}'
    location: location
    enablePurgeProtection: false
    enableRbacAuthorization: true
    roleAssignments: [
      {
        principalIds: [
          userID
        ]
        principalType: 'User'
        roleDefinitionIdOrName: 'Key Vault Secrets User'
      }
    ]
    secrets: {
      secureList: [
        {
          name: 'ubuntu01-admpassword'
          value: privateKeyData
        }
      ]
    }
  }
}
