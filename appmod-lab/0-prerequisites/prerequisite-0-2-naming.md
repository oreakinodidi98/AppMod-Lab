---
title: Naming
description: Choose consistent names for the Azure resources you create in this workshop.
parent: Prerequisites
nav_order: 2
---

## Naming conventions

Module 03 creates names using an owner code, environment, region code, and
random suffix. Choose the codes with your facilitator before creating resources:

```text
<owner>-<environment>-<region>-<random-suffix>
```

For example, `oa-dev-sc-123456` uses owner code `oa`, development, and Sweden
Central. A participant using `mw` in West US could use `mw-dev-usw-123456`.
These are examples, not reserved names. Use a short code rather than a full
name or sensitive information.

In module 03, edit `oa-dev-sc` in `$env:NAME_PREFIX` and set `$env:LOCATION`
to the corresponding approved Azure location. For example, use `westus` for
West US. The command adds a random six-digit suffix; keep it so participants
are less likely to choose the same resource names.

Use a two-character owner code, `dev` for this workshop, and a two- or
three-character region code. Use lowercase letters and numbers only in the
codes. Module 03 adds service prefixes and removes hyphens for the container
registry, which permits only letters and numbers:

| Resource | Example |
| --- | --- |
| Resource group | `rg-oa-dev-sc-123456` |
| AKS cluster | `aks-oa-dev-sc-123456` |
| PostgreSQL server | `pg-oa-dev-sc-123456` |
| Managed identity | `mi-oa-dev-sc-123456` |
| Container registry | `acroadevsc123456` |
| Key Vault | `kv-oa-dev-sc-123456` |

Registry, PostgreSQL, and Key Vault names must be globally unique. A random
suffix reduces collisions but does not guarantee availability. If a name is
already taken, choose a new suffix before creating resources; do not reuse
another participant's resources. Record the actual values saved in `.envrc`
for later steps and cleanup.

For existing environments, keep their recorded names; changing these examples
does not rename resources. Azure-managed resources such as the AKS node
resource group may have service-generated names. See the
[Azure resource naming rules](https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules)
for service-specific restrictions.

[Next: interactive modernization]({{ site.baseurl }}{% link appmod-lab/1-interactive-modernization/index.md %}) |
[Workshop home]({{ site.baseurl }}{% link index.md %})
