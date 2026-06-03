# Deploy — Static Web App test resources

Deploys two Standard-tier Static Web Apps into an existing resource group:

| Resource | Name pattern | Notes |
|---|---|---|
| Virtual Network | `vnet-{prefix}` | `10.0.0.0/16`, one subnet `snet-pe` |
| Static Web App (public) | `stapp-{prefix}-public` | No private endpoint |
| Static Web App (private) | `stapp-{prefix}-private` | Connected via private endpoint |
| Private Endpoint | `pep-{prefix}-stapp` | Targets `stapp-{prefix}-private` |
| Private DNS Zone | `privatelink.azurestaticapps.net` | Global resource |
| DNS Zone VNet Link | `link-{prefix}-vnet` | Links the zone to the VNet |

## Public network access behaviour

Azure Static Web Apps change their default public-access behaviour as soon as a private endpoint is attached:

| `publicNetworkAccess` | Private endpoint present | Public endpoint reachable |
|---|---|---|
| `null` (unset) | No | Yes |
| `null` (unset) | Yes | **No — returns 403** |
| `'Enabled'` | Yes | Yes |
| `'Disabled'` | Either | No |

When a private endpoint exists, `null` is treated as disabled. You must explicitly set `publicNetworkAccess: 'Enabled'` to keep the public endpoint open alongside a private one.

## Prerequisites

- Azure CLI ≥ 2.60 with Bicep CLI (`az bicep install`)
- An existing resource group
- Contributor rights on the resource group

## Create the resource group

```bash
az group create --name <rg-name> --location <region>
```

## Deploy

```bash
az deployment group create \
  --resource-group <rg-name> \
  --template-file deploy/main.bicep \
  --parameters namePrefix=<prefix> location=<region>
```

**Parameters**

| Parameter | Required | Default | Description |
|---|---|---|---|
| `namePrefix` | No | `3141cb76` | Short string included in every resource name |
| `location` | No | Resource group location | Azure region, e.g. `westeurope` |
| `tags` | No | `{}` | Tags applied to all resources |

**Example**

```bash
az deployment group create \
  --resource-group rg-policy-test \
  --template-file deploy/main.bicep \
  --parameters namePrefix=myapp location=westeurope
```

## Tear down

```bash
az group delete --name <rg-name> --yes
```
