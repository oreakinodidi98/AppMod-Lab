---
title: Naming
description: Choose consistent names for the Azure resources you create in this workshop.
parent: Prerequisites
nav_order: 2
---

## Naming conventions

Before deploying any Azure services, choose the names you will use throughout
the workshop. This follows the
[Azure naming guidance](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming).

We include the application, environment, region, owner, and instance number.
Start with these defaults:

| Setting | Default | Meaning |
| --- | --- | --- |
| Application | `hol` | Hands On Lab |
| Environment | `dev` | Development |
| Region | `sc` | Sweden Central (`swedencentral` in Azure CLI) |
| Owner | `oa` | Lab owner code |
| Instance | `01` | Two-digit instance number |

Use your own short owner code or a different instance if you share a subscription.
Some names, including ACR, PostgreSQL, storage, and Key Vault names, must be
globally unique. The default names are examples, not reserved names.
Use codes, not personal or sensitive information.

For services that allow dashes:

```text
<service-prefix>-<environment>-<region>-<application-name>-<owner>-<instance>
```

For services that allow only letters and numbers:

```text
<service-prefix><environment><region><application-name><owner><instance>
```

With the defaults, the names are:

| Resource | Name |
| --- | --- |
| Resource group | `rg-dev-sc-hol-oa-01` |
| AKS cluster | `aks-dev-sc-hol-oa-01` |
| Container registry | `crdevscholoa01` |
| PostgreSQL server | `psql-dev-sc-hol-oa-01` |
| Caldova database | `dbdevscholoa01` |
| Managed identity | `id-dev-sc-hol-oa-01` |
| Key Vault, in the reference scripts | `kv-dev-sc-hol-oa-01` |
| Storage account example | `stdevscholoa01` |

The workshop does not create a storage account. It is included to show the
no-dashes format. The provisioning commands also add `application`,
`environment`, `region`, `owner`, and `instance` tags to the top-level resources they create.

### Choose your values

Run this in the same PowerShell terminal you used for setup. Press Enter to
accept each default. Keep the instance as two digits, such as `01` or `02`.
Use lowercase letters and numbers for the other codes, starting with a letter.

```powershell
$defaults = [ordered]@{
    LAB_APPLICATION = 'hol'
    LAB_ENVIRONMENT = 'dev'
    LAB_REGION_CODE = 'sc'
    LAB_OWNER = 'oa'
    LAB_INSTANCE = '01'
    LAB_LOCATION = 'swedencentral'
}
foreach ($entry in $defaults.GetEnumerator()) {
    $value = Read-Host "$($entry.Key) [$($entry.Value)]"
    if ([string]::IsNullOrWhiteSpace($value)) { $value = $entry.Value }
    Set-Item -Path "Env:$($entry.Key)" -Value $value
}
```

Have the facilitator approve the region. If you change it, update both its short
code and Azure CLI location; `sc` always means `swedencentral`.
Record the chosen values with your other lab settings. Keep the same values
until cleanup. If a global name is taken, choose another owner or instance
**before** creating any resources; do not silently reuse an existing resource.

These names apply to new deployments. Changing the naming settings does not
rename existing Azure resources. If you already created an environment using
the previous names, keep its recorded names and confirm cleanup with its owner
before starting a new deployment.

### How the scripts use these names

Module 03 downloads `assets/scripts/lab-names.ps1` into your workshop repository.
The deployment instructions and both reference setup scripts use its
`Get-LabResourceNames` function, so names are generated in one place. It rejects
invalid codes and names that are too long instead of shortening them silently.
The cleanup steps check the recorded resource group against the same pattern.

The reference scripts accept `-Application`, `-Environment`, `-RegionCode`,
`-Owner`, `-Instance`, and `-Location`. Their defaults match the table above.
They remain reference scripts, not the student provisioning path.

Some Azure resources have stricter rules. AKS node pool names are limited to
12 characters for Linux, so the classic reference script uses `sys01` and
`usr01`, based on the instance. Azure-managed resources, such as the AKS node
resource group and automatic monitoring resources, can have service-generated
names. Record those actual names rather than trying to rename them.
See the [service naming rules](https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules).

[Next: interactive modernization]({% link appmod-lab/1-interactive-modernization/index.md %}) |
[Workshop home]({% link index.md %})
