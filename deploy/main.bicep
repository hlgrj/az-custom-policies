@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('Prefix applied to all resource names.')
param namePrefix string = '3141cb76'

param tags object = {}

// ── Networking ────────────────────────────────────────────────────────────────

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-${namePrefix}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: 'snet-pe'
        properties: {
          addressPrefix: '10.0.0.0/24'
          // Required to allow private endpoint NICs in this subnet.
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

// ── Static Web Apps ───────────────────────────────────────────────────────────

resource swaPublic 'Microsoft.Web/staticSites@2025-03-01' = {
  name: 'stapp-${namePrefix}-public'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {}
}

resource swaPrivate 'Microsoft.Web/staticSites@2025-03-01' = {
  name: 'stapp-${namePrefix}-private'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {}
}

// ── Private endpoint for swaPrivate ──────────────────────────────────────────

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pep-${namePrefix}-stapp'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: '${vnet.id}/subnets/snet-pe'
    }
    privateLinkServiceConnections: [
      {
        name: 'conn-${namePrefix}-stapp'
        properties: {
          privateLinkServiceId: swaPrivate.id
          // 'staticSites' is the private link sub-resource type for Static Web Apps.
          groupIds: ['staticSites']
        }
      }
    ]
  }
}

// ── Private DNS zone ──────────────────────────────────────────────────────────

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurestaticapps.net'
  // Private DNS zones are global resources.
  location: 'global'
  tags: tags
}

resource dnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: 'link-${namePrefix}-vnet'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    // Auto-registration is for VMs; private endpoints self-register via the zone group below.
    registrationEnabled: false
  }
}

// Wires the private endpoint NIC into the DNS zone so the SWA hostname resolves
// to the private IP inside the VNet.
resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azurestaticapps-net'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

output swaPublicHostname string = swaPublic.properties.defaultHostname
output swaPrivateHostname string = swaPrivate.properties.defaultHostname
output privateEndpointId string = privateEndpoint.id
output privateDnsZoneId string = privateDnsZone.id
