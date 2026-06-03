# Custom Azure Policies for Azure Static Web Apps

Custom Azure Policy definitions for Azure Static Web Apps, with Bicep-based test infrastructure. Each policy ships with a definition JSON, a parameterised test deployment, and a documented test sequence.

See [CONTRIBUTING.md](CONTRIBUTING.md) to add a new policy.

## Policies

| Policy | Resource type | Category | Version | Default effect |
|---|---|---|---|---|
| [Audit public network access](#azure-static-web-apps-should-have-public-network-access-disabled) | `Microsoft.Web/staticSites` | App Service | 1.3.0 | Audit |
| [Enforce CAF naming convention](#enforce-caf-naming-convention-stapp--prefix) | `Microsoft.Web/staticSites` | App Service | 1.0.0 | Deny |
| [Require Standard SKU](#azure-static-web-apps-should-use-the-standard-sku) | `Microsoft.Web/staticSites` | App Service | 1.0.0 | Audit |
| [Require private endpoint](#azure-static-web-apps-should-use-a-private-endpoint) | `Microsoft.Web/staticSites` | App Service | 1.0.0 | Audit only |
| [Require custom domain](#azure-static-web-apps-should-use-a-custom-domain) | `Microsoft.Web/staticSites` | App Service | 1.0.0 | Audit only |
| [Restrict repository organization](#azure-static-web-apps-should-be-connected-to-an-approved-github-organization) | `Microsoft.Web/staticSites` | App Service | 1.0.0 | Audit |

---

### Azure Static Web Apps should have public network access disabled

**Definition:** [`definitions/static-web-app-public-network-access.json`](definitions/static-web-app-public-network-access.json)  
**Resource type:** `Microsoft.Web/staticSites`  
**Effects:** `Audit` (default), `Deny`, `Disabled`  
**Category:** App Service  
**Version:** 1.3.0

Audits Standard-tier Azure Static Web Apps that have public network access enabled. Resources that omit `publicNetworkAccess` are also flagged, because Azure defaults to public access when the field is absent. The policy is scoped to Standard SKU only — Free-tier apps cannot use private endpoints and have no compliant alternative to public access.

---

### Enforce CAF naming convention (stapp- prefix)

**Definition:** [`definitions/deny-static-web-app-naming-convention.json`](definitions/deny-static-web-app-naming-convention.json)  
**Resource type:** `Microsoft.Web/staticSites`  
**Effects:** `Deny` (default), `Audit`, `Disabled`  
**Category:** App Service  
**Version:** 1.0.0

Denies creation of Azure Static Web Apps whose name does not start with the `stapp-` prefix, as required by the [Microsoft Cloud Adoption Framework abbreviation recommendations](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations). The prefix check is case-insensitive. Because Static Web App names are immutable, the Deny effect is the only enforcement option — there is no in-place remediation path.

---

### Azure Static Web Apps should use the Standard SKU

**Definition:** [`definitions/static-web-app-standard-sku.json`](definitions/static-web-app-standard-sku.json)  
**Resource type:** `Microsoft.Web/staticSites`  
**Effects:** `Audit` (default), `Deny`, `Disabled`  
**Category:** App Service  
**Version:** 1.0.0

Audits Azure Static Web Apps deployed on the Free tier. Standard tier is a prerequisite for enterprise security features including private endpoints, enterprise-grade CDN, and managed identity integrations. Set the effect to `Deny` to block creation or update of Free-tier apps, or `Audit` to report non-compliant resources without blocking.

---

### Azure Static Web Apps should use a private endpoint

**Definition:** [`definitions/static-web-app-private-endpoint.json`](definitions/static-web-app-private-endpoint.json)  
**Resource type:** `Microsoft.Web/staticSites`  
**Effects:** `Audit` (default), `Disabled`  
**Category:** App Service  
**Version:** 1.0.0

Audits Standard-tier Azure Static Web Apps that have no private endpoint connections. A private endpoint ensures traffic traverses the Microsoft backbone rather than the public internet, and is required to enforce meaningful network isolation when public network access is disabled. The policy is scoped to Standard SKU resources only — Free-tier apps do not support private endpoints and are addressed by the SKU policy.

---

### Azure Static Web Apps should use a custom domain

**Definition:** [`definitions/static-web-app-custom-domain.json`](definitions/static-web-app-custom-domain.json)  
**Resource type:** `Microsoft.Web/staticSites`  
**Effects:** `Audit` (default), `Disabled`  
**Category:** App Service  
**Version:** 1.0.0

Audits Azure Static Web Apps that have no custom domain configured. Apps without a custom domain are only reachable via the Microsoft-managed default hostname (`*.azurestaticapps.net`), which prevents branded endpoints and customer-managed TLS. Applies to both Free and Standard tier. Deny is not supported because custom domains are child resources managed outside the Static Web App's PUT body — enforcing Deny would block all Static Web App deployments regardless of actual domain state.

---

### Azure Static Web Apps should be connected to an approved GitHub organization

**Definition:** [`definitions/static-web-app-allowed-repository-organizations.json`](definitions/static-web-app-allowed-repository-organizations.json)  
**Resource type:** `Microsoft.Web/staticSites`  
**Effects:** `Audit` (default), `Deny`, `Disabled`  
**Category:** App Service  
**Version:** 1.0.0

Audits or denies Azure Static Web Apps whose `repositoryUrl` does not begin with one of the approved GitHub organization prefixes supplied via the `allowedOrganizations` parameter. Apps connected to repositories outside approved organizations bypass supply-chain controls and source-code governance. Apps with no `repositoryUrl` (deployed via CI/CD without a GitHub integration) are excluded. Start with `Audit` to inventory existing connections, then switch to `Deny` once all approved organizations are confirmed.

---

## Repository structure

```
definitions/          Policy definition JSON files (one per policy)
deploy/               Standalone Bicep deployment for manual testing (see deploy/README.md)
tests/
  modules/            Reusable Bicep modules shared across test deployments
  <policy-name>/      Per-policy test folder (name matches definition filename)
    resources.bicep   Deploys test resources covering all test scenarios
    policy.bicep      Deploys the policy definition and assignment (subscription scope)
    TEST-CASES.md     Test case table and step-by-step test sequence
```

See [deploy/README.md](deploy/README.md) for instructions on deploying a self-contained set of test resources.

## Testing

Each policy has a dedicated folder under `tests/` with Bicep deployments and a test guide.

The general test flow is:

1. Deploy test resources **before** policy assignment (`includeNonCompliant=true`) to seed pre-existing non-compliant resources.
2. Assign the policy in **Audit** mode and verify the compliance scan catches the expected resources.
3. Switch the policy to **Deny** mode and verify that non-compliant deployments are blocked while compliant ones succeed.
4. Where applicable, verify remediation by updating a non-compliant resource to a compliant state.

See the `TEST-CASES.md` in each test folder for the full test case table and exact commands.

### Prerequisites

- Azure CLI (`az`) with an active login
- Contributor and Resource Policy Contributor rights on the target subscription/resource group
