---
title: Module 03 - Create the Azure environment
description: Provision a disposable AKS, ACR, PostgreSQL, and workload identity environment using participant-selected settings.
ms.topic: tutorial
nav_order: 4
---

## Goals

Create a new, dedicated resource group containing an AKS Automatic cluster, an
Azure Container Registry (ACR), Azure Database for PostgreSQL, and a user-assigned
managed identity. Configure the identity so both Caldova implementations can read
the same database without a stored database password.

> [!WARNING]
> These steps create billable resources and make role assignments. Use only a
> subscription, region, network design, and budget approved for this workshop.
> Do not use an existing resource group: [cleanup](../7-cleanup/) deletes the
> entire group and everything in it.

The lab uses AKS Automatic's managed networking, a public AKS API, and a public
PostgreSQL endpoint restricted to the workstation and AKS outbound IPv4 addresses.
The applications are exposed locally through port forwarding, not a public
application route. AKS Automatic can also provision managed ingress or Gateway
resources; review its defaults and associated costs with the platform team. For
production, decide on private networking, egress, availability zones, monitoring,
and access controls with the platform team before creating the cluster.

## 1. Select the subscription and lab settings

Use the PowerShell terminal from [module 00](../0-prerequisites/prerequisite-0-1-technical/). The following
setting makes native-command failures stop subsequent PowerShell commands:

```powershell
Set-Location -LiteralPath $env:LAB_REPO
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

az login --output none
az account list --query "[].{Name:name,Id:id,Default:isDefault}" --output table
$subscription = Read-Host 'Approved subscription name or ID'
az account set --subscription $subscription
$env:LAB_SUBSCRIPTION = (az account show --query id --output tsv).Trim()
az account show --query "{Name:name,Id:id,Tenant:tenantId}" --output table

if ((az account show --query user.type --output tsv).Trim() -ne 'user') {
    throw 'Use an interactive Microsoft Entra user account for this lab.'
}
$env:LAB_ADMIN_UPN = (az ad signed-in-user show --query userPrincipalName --output tsv).Trim()
$env:LAB_ADMIN_OBJECT_ID = (az ad signed-in-user show --query id --output tsv).Trim()
if (-not $env:LAB_ADMIN_UPN -or -not $env:LAB_ADMIN_OBJECT_ID) {
    throw 'Could not resolve the signed-in Microsoft Entra user.'
}
```

Confirm the displayed subscription and tenant before continuing. Choose settings
that your subscription, region, and budget permit. Check the
[AKS Automatic region and CLI requirements](https://learn.microsoft.com/azure/aks/automatic/quick-automatic-managed-network)
and the available PostgreSQL options with your facilitator.

```powershell
az account list-locations --query "[].{Name:name,Display:displayName}" --output table
$env:LAB_LOCATION = Read-Host 'Approved Azure region'
az postgres flexible-server list-skus --location $env:LAB_LOCATION --output table
$env:LAB_PREFIX = Read-Host 'Short lab prefix: 3 to 10 lowercase letters or digits, starting with a letter'
if ($env:LAB_PREFIX -cnotmatch '^[a-z][a-z0-9]{2,9}$') {
    throw 'The lab prefix must be 3 to 10 lowercase letters or digits and start with a letter.'
}

$env:LAB_PG_TIER = Read-Host 'Approved PostgreSQL tier: Burstable, GeneralPurpose, or MemoryOptimized'
$env:LAB_PG_SKU = Read-Host 'Approved PostgreSQL SKU for that tier and region'
$env:LAB_PG_VERSION = Read-Host 'Supported PostgreSQL major version, 15 or later'
$env:LAB_PG_STORAGE = Read-Host 'PostgreSQL storage in GiB, at least 32'
$env:LAB_CLIENT_IP = Read-Host 'Public outbound IPv4 address of this workstation or its network'

if ($env:LAB_PG_TIER -notin @('Burstable', 'GeneralPurpose', 'MemoryOptimized')) {
    throw 'Choose a supported PostgreSQL tier.'
}
$majorVersion = 0
$storageGiB = 0
if (-not [int]::TryParse($env:LAB_PG_VERSION, [ref]$majorVersion) -or $majorVersion -lt 15) {
    throw 'Choose a supported PostgreSQL major version of at least 15.'
}
if (-not [int]::TryParse($env:LAB_PG_STORAGE, [ref]$storageGiB) -or $storageGiB -lt 32) {
    throw 'Choose at least 32 GiB of PostgreSQL storage.'
}
$clientAddress = [System.Net.IPAddress]::Parse($env:LAB_CLIENT_IP)
$ipBytes = $clientAddress.GetAddressBytes()
if ($clientAddress.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork -or
    $ipBytes[0] -in @(0, 10, 127) -or $ipBytes[0] -ge 224 -or
    ($ipBytes[0] -eq 100 -and $ipBytes[1] -ge 64 -and $ipBytes[1] -le 127) -or
    ($ipBytes[0] -eq 169 -and $ipBytes[1] -eq 254) -or
    ($ipBytes[0] -eq 172 -and $ipBytes[1] -ge 16 -and $ipBytes[1] -le 31) -or
    ($ipBytes[0] -eq 192 -and $ipBytes[1] -eq 168)) {
    throw 'Enter the approved public outbound IPv4 address, not a private, shared, or loopback address.'
}
```

Generate names from your prefix and a random suffix. No subscription, tenant,
resource name, registry, database host, or identity from the original demo is used.
The generated names are kept in this terminal's environment only.

```powershell
$env:LAB_SUFFIX = [guid]::NewGuid().ToString('N').Substring(0, 8)
$env:LAB_RG = "$($env:LAB_PREFIX)-rg-$($env:LAB_SUFFIX)"
$env:LAB_AKS = "$($env:LAB_PREFIX)-aks-$($env:LAB_SUFFIX)"
$env:LAB_ACR = "$($env:LAB_PREFIX)acr$($env:LAB_SUFFIX)"
$env:LAB_PG_SERVER = "$($env:LAB_PREFIX)-pg-$($env:LAB_SUFFIX)"
$env:LAB_PG_DATABASE = "$($env:LAB_PREFIX)$($env:LAB_SUFFIX)"
$env:LAB_IDENTITY = "$($env:LAB_PREFIX)-mi-$($env:LAB_SUFFIX)"
$env:LAB_FEDERATION = "$($env:LAB_PREFIX)-federation"
$env:LAB_NAMESPACE = "$($env:LAB_PREFIX)-$($env:LAB_SUFFIX)"
$env:LAB_SERVICE_ACCOUNT = "$($env:LAB_PREFIX)-api"
$env:LAB_API_NAME = "$($env:LAB_PREFIX)-api"
$env:LAB_WEB_NAME = "$($env:LAB_PREFIX)-web"
$env:LAB_CONFIG_NAME = "$($env:LAB_PREFIX)-settings"
$env:KUBECONFIG = Join-Path ([IO.Path]::GetTempPath()) "caldova-$($env:LAB_SUFFIX).kubeconfig"

"Resource group: $env:LAB_RG"
"Prefix and suffix: $env:LAB_PREFIX, $env:LAB_SUFFIX"
"AKS cluster: $env:LAB_AKS"
"Registry: $env:LAB_ACR"
"PostgreSQL server: $env:LAB_PG_SERVER"
"PostgreSQL database: $env:LAB_PG_DATABASE"
"Managed identity: $env:LAB_IDENTITY"
"Namespace: $env:LAB_NAMESPACE"
"Service account: $env:LAB_SERVICE_ACCOUNT"
"Temporary kubeconfig path: $env:KUBECONFIG"
```

Record these non-secret values and the selected subscription in a private location
for recovery and cleanup. Keep the terminal open. Never record access tokens in
those notes.

## 2. Check prerequisites before creating resources

```powershell
$providers = @(
    'Microsoft.ContainerService', 'Microsoft.ContainerRegistry',
    'Microsoft.DBforPostgreSQL', 'Microsoft.ManagedIdentity',
    'Microsoft.Network', 'Microsoft.Compute', 'Microsoft.PolicyInsights',
    'Microsoft.Insights', 'Microsoft.AlertsManagement', 'Microsoft.Monitor',
    'Microsoft.OperationalInsights'
)
foreach ($provider in $providers) {
    $state = (az provider show --namespace $provider --query registrationState --output tsv).Trim()
    if ($state -ne 'Registered') {
        throw "$provider is $state. Ask the subscription administrator to register it before continuing."
    }
}

$groupExists = (az group exists --name $env:LAB_RG --output tsv).Trim()
if ($groupExists -ne 'false') {
    throw 'The resource group already exists or could not be verified. Choose a new lab name.'
}
$registryAvailable = (az acr check-name --name $env:LAB_ACR --query nameAvailable --output tsv).Trim()
if ($registryAvailable -ne 'true') {
    throw 'The registry name is unavailable. Restart this module with a new prefix or suffix.'
}
if (Test-Path -LiteralPath $env:KUBECONFIG) {
    throw 'The temporary kubeconfig path already exists. Restart with a new lab suffix.'
}
az aks get-versions --location $env:LAB_LOCATION --output table
```

Confirm quota, PostgreSQL SKU availability, role-assignment permissions, the
workstation's public IP, and the estimated cost with the facilitator. If a check
fails, stop and resolve it. Do not change subscription-wide registration or policy
without authorization.

## 3. Create the registry and cluster

Confirm that the resource group name shown above is new and dedicated to this lab:

```powershell
if ((Read-Host 'Type create to provision the displayed lab resources') -cne 'create') {
    throw 'Provisioning was not confirmed.'
}
az group create --name $env:LAB_RG --location $env:LAB_LOCATION --output none
az acr create --resource-group $env:LAB_RG --name $env:LAB_ACR `
    --location $env:LAB_LOCATION --sku Basic --role-assignment-mode rbac --output none

$env:LAB_REGISTRY = (az acr show --resource-group $env:LAB_RG --name $env:LAB_ACR `
    --query loginServer --output tsv).Trim()
$registryMode = (az acr show --resource-group $env:LAB_RG --name $env:LAB_ACR `
    --query roleAssignmentMode --output tsv).Trim()
if (-not $env:LAB_REGISTRY -or $registryMode -ne 'LegacyRegistryPermissions') {
    throw 'The registry login server or RBAC registry permission mode could not be verified.'
}

az aks create --resource-group $env:LAB_RG --name $env:LAB_AKS `
    --location $env:LAB_LOCATION --sku automatic --attach-acr $env:LAB_ACR `
    --enable-oidc-issuer --enable-workload-identity --output none
```

Cluster creation can take a while. `--attach-acr` creates a registry role assignment
for the cluster's kubelet identity. It requires permission to create that assignment
and does not support registries using **RBAC Registry + ABAC Repository
Permissions**. See [AKS and ACR integration](https://learn.microsoft.com/azure/aks/cluster-container-registry-integration).
If your organization requires a different registry permission mode, stop and work
with its administrator on an approved configuration. The CLI's `rbac` creation
option is reported as `LegacyRegistryPermissions` by the registry API.

Record the managed node resource group and inspect the cluster's monitoring
configuration before deletion:

```powershell
$env:LAB_NODE_RG = (az aks show --resource-group $env:LAB_RG --name $env:LAB_AKS `
    --query nodeResourceGroup --output tsv).Trim()
if (-not $env:LAB_NODE_RG) { throw 'Could not resolve the AKS node resource group.' }
az aks show --resource-group $env:LAB_RG --name $env:LAB_AKS `
    --query "{NodeGroup:nodeResourceGroup,Addons:addonProfiles,AzureMonitor:azureMonitorProfile}" --output json
```

AKS Automatic may enable monitoring and create or reuse workspaces outside the lab
resource group. Identify those workspaces with the platform owner, record whether
they are shared, and include their costs and ownership in the cleanup plan. Do not
delete a shared workspace.

Connect using an isolated kubeconfig instead of overwriting your normal one:

```powershell
az aks get-credentials --resource-group $env:LAB_RG --name $env:LAB_AKS `
    --file $env:KUBECONFIG
kubelogin convert-kubeconfig --login azurecli --kubeconfig $env:KUBECONFIG
kubectl get nodes
```

Confirm that the command reaches the new cluster. The workshop uses its own
namespace and does not change the default namespace.

## 4. Create PostgreSQL and the workload identity

Create the identity and an Entra-only PostgreSQL server. The first firewall rule
allows the workstation IP you supplied; the AKS egress rules are added next.

```powershell
az identity create --resource-group $env:LAB_RG --name $env:LAB_IDENTITY `
    --location $env:LAB_LOCATION --output none
$env:LAB_IDENTITY_CLIENT_ID = (az identity show --resource-group $env:LAB_RG `
    --name $env:LAB_IDENTITY --query clientId --output tsv).Trim()
$env:LAB_IDENTITY_OBJECT_ID = (az identity show --resource-group $env:LAB_RG `
    --name $env:LAB_IDENTITY --query principalId --output tsv).Trim()
if (-not $env:LAB_IDENTITY_CLIENT_ID -or -not $env:LAB_IDENTITY_OBJECT_ID) {
    throw 'Could not resolve the managed identity.'
}

az postgres flexible-server create --resource-group $env:LAB_RG `
    --name $env:LAB_PG_SERVER --location $env:LAB_LOCATION `
    --tier $env:LAB_PG_TIER --sku-name $env:LAB_PG_SKU `
    --version $env:LAB_PG_VERSION --storage-size $env:LAB_PG_STORAGE `
    --microsoft-entra-auth Enabled --password-auth Disabled `
    --admin-display-name $env:LAB_ADMIN_UPN --admin-object-id $env:LAB_ADMIN_OBJECT_ID `
    --admin-type User --public-access $env:LAB_CLIENT_IP --output none

$env:LAB_PG_HOST = (az postgres flexible-server show --resource-group $env:LAB_RG `
    --name $env:LAB_PG_SERVER --query fullyQualifiedDomainName --output tsv).Trim()
if (-not $env:LAB_PG_HOST) { throw 'Could not resolve the PostgreSQL host.' }
```

If creation fails, inspect the Azure error and the partially created resources.
Do not assume the command rolled them back. Use the same resource group for
[cleanup](../7-cleanup/) when appropriate.

### Allow the cluster's outbound addresses

AKS Automatic uses a managed NAT gateway for outbound traffic. The following
commands discover the public IP resources attached to the gateway and add one
PostgreSQL rule per address. They stop if the network uses a different outbound type
or public IP prefixes. In that case, ask the network administrator for an approved
design rather than opening a broad firewall rule.

```powershell
$outboundType = (az aks show --resource-group $env:LAB_RG --name $env:LAB_AKS `
    --query networkProfile.outboundType --output tsv).Trim()
if ($outboundType -notin @('managedNATGateway', 'managedNATGatewayV2')) {
    throw "Unsupported outbound type for this exercise: $outboundType"
}
if (-not $env:LAB_NODE_RG) { throw 'Could not resolve the AKS node resource group.' }

$natIds = @(az network vnet list --resource-group $env:LAB_NODE_RG `
    --query "[].subnets[].natGateway.id" --output tsv |
    Where-Object { $_ } | Sort-Object -Unique)
if ($natIds.Count -eq 0) { throw 'No AKS NAT gateway was found.' }

$egressIPs = @(
    foreach ($natId in $natIds) {
        $nat = az network nat gateway show --ids $natId --output json | ConvertFrom-Json
        if (@($nat.publicIpPrefixes | Where-Object { $_ }).Count -gt 0) {
            throw 'The NAT gateway uses an IP prefix. Ask the network administrator for approved firewall rules.'
        }
        foreach ($address in @($nat.publicIpAddresses | Where-Object { $_.id })) {
            $ip = (az network public-ip show --ids $address.id --query ipAddress --output tsv).Trim()
            if (-not $ip) { throw 'Could not resolve an AKS outbound public IP.' }
            $ip
        }
    }
)
if ($egressIPs.Count -eq 0) { throw 'No AKS outbound public IPs were found.' }
$ruleNumber = 0
foreach ($ip in ($egressIPs | Sort-Object -Unique)) {
    $ruleNumber++
    az postgres flexible-server firewall-rule create --resource-group $env:LAB_RG `
        --name "$($env:LAB_PREFIX)-egress-$ruleNumber" --server-name $env:LAB_PG_SERVER `
        --start-ip-address $ip --end-ip-address $ip --output none
}
```

The rules are only valid while these outbound addresses remain current. If your
workstation IP or cluster egress changes, review the rules with the facilitator.
Do not use the `0.0.0.0` Azure-services exception.

### Trust the Kubernetes service account

```powershell
$issuer = (az aks show --resource-group $env:LAB_RG --name $env:LAB_AKS `
    --query oidcIssuerProfile.issuerUrl --output tsv).Trim()
if (-not $issuer) { throw 'The AKS OIDC issuer is unavailable.' }
$subject = 'system:serviceaccount:{0}:{1}' -f $env:LAB_NAMESPACE, $env:LAB_SERVICE_ACCOUNT
az identity federated-credential create --resource-group $env:LAB_RG `
    --identity-name $env:LAB_IDENTITY --name $env:LAB_FEDERATION `
    --issuer $issuer --subject $subject --audiences api://AzureADTokenExchange --output none

kubectl create namespace $env:LAB_NAMESPACE
kubectl create serviceaccount $env:LAB_SERVICE_ACCOUNT --namespace $env:LAB_NAMESPACE
kubectl annotate serviceaccount $env:LAB_SERVICE_ACCOUNT --namespace $env:LAB_NAMESPACE `
    "azure.workload.identity/client-id=$env:LAB_IDENTITY_CLIENT_ID"
```

The federation subject, namespace, and service account must match exactly. Allow
time for the new identity and federation to propagate before investigating a token
exchange failure.

## 5. Initialize and authorize the database

Use a short-lived Microsoft Entra token as the PostgreSQL password for `psql`.
The token remains in this process environment and is removed even if a command
fails. Do not print, save, or paste it into a file.

```powershell
$env:PGHOST = $env:LAB_PG_HOST
$env:PGPORT = '5432'
$env:PGUSER = $env:LAB_ADMIN_UPN
$env:PGSSLMODE = 'require'

try {
    $env:PGPASSWORD = (az account get-access-token --resource-type oss-rdbms `
        --query accessToken --output tsv).Trim()
    if (-not $env:PGPASSWORD) { throw 'Could not obtain a PostgreSQL access token.' }

    $principalSql = @'
SELECT * FROM pg_catalog.pgaadauth_create_principal_with_oid(
    :'principal_name', :'principal_id', 'service', false, false
);
'@
    $principalSql | & psql --dbname postgres --set=ON_ERROR_STOP=1 `
        "--set=principal_name=$env:LAB_IDENTITY" "--set=principal_id=$env:LAB_IDENTITY_OBJECT_ID"

    $createDatabaseSql = 'CREATE DATABASE :"database_name";'
    $createDatabaseSql | & psql --dbname postgres --set=ON_ERROR_STOP=1 `
        "--set=database_name=$env:LAB_PG_DATABASE"

    $seedFile = Join-Path -Path $env:LAB_REPO -ChildPath 'Python_app' `
        -AdditionalChildPath 'CaldovaClinicalApi', 'db', 'init.sql'
    & psql --dbname $env:LAB_PG_DATABASE --set=ON_ERROR_STOP=1 --file $seedFile

    $grantSql = @'
GRANT CONNECT ON DATABASE :"database_name" TO :"principal_name";
GRANT USAGE ON SCHEMA pharmacy TO :"principal_name";
GRANT SELECT ON ALL TABLES IN SCHEMA pharmacy TO :"principal_name";
'@
    $grantSql | & psql --dbname $env:LAB_PG_DATABASE --set=ON_ERROR_STOP=1 `
        "--set=database_name=$env:LAB_PG_DATABASE" "--set=principal_name=$env:LAB_IDENTITY"

    & psql --dbname $env:LAB_PG_DATABASE --set=ON_ERROR_STOP=1 `
        --command 'SELECT count(*) AS inventory_lots FROM pharmacy.inventory_lots;'
}
finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}
```

The Entra administrator creates and owns the database for initialization; the
application uses the separate read-only identity. The database should contain six
seeded inventory lots. If database or principal creation reports an existing
object after a partial run, inspect its ownership and contents before resuming.
For a principal, verify its object ID using the
[Entra role guidance](https://learn.microsoft.com/azure/postgresql/security/security-manage-entra-users).
Do not assume it belongs to the intended identity.

The sample applications require encrypted PostgreSQL connections. Their current
`require` TLS settings do not demonstrate full certificate and hostname validation;
evaluate stronger verification and trusted certificate configuration before using
this pattern in production.

## 6. Prepare safe image-build contexts

ACR uploads the complete build context. Some existing demo folders contain
environment-specific files, so do not pass those folders directly to `az acr build`.
Create a temporary context containing only the committed files needed by the four
Dockerfiles:

```powershell
$env:LAB_BUILD_ROOT = Join-Path ([IO.Path]::GetTempPath()) "caldova-build-$($env:LAB_SUFFIX)"
if (Test-Path -LiteralPath $env:LAB_BUILD_ROOT) {
    throw 'The temporary build directory already exists.'
}
New-Item -ItemType Directory -Path $env:LAB_BUILD_ROOT | Out-Null
$archive = Join-Path $env:LAB_BUILD_ROOT 'source.tar'
$sourcePaths = @(
    'Python_app\CaldovaClinicalApi\Dockerfile',
    'Python_app\CaldovaClinicalApi\requirements.txt',
    'Python_app\CaldovaClinicalApi\main.py',
    'Python_app\CaldovaClinicalWeb\Dockerfile',
    'Python_app\CaldovaClinicalWeb\requirements.txt',
    'Python_app\CaldovaClinicalWeb\app.py',
    'Python_app\CaldovaClinicalWeb\caldova_home.py',
    'Java_app\CaldovaClinicalApiJava\Dockerfile',
    'Java_app\CaldovaClinicalApiJava\pom.xml',
    'Java_app\CaldovaClinicalApiJava\src',
    'Java_app\CaldovaClinicalWebJava\Dockerfile',
    'Java_app\CaldovaClinicalWebJava\pom.xml',
    'Java_app\CaldovaClinicalWebJava\src'
)
git archive --format=tar --output $archive HEAD -- $sourcePaths
tar -xf $archive -C $env:LAB_BUILD_ROOT
Remove-Item -LiteralPath $archive
git --no-pager log -1 --format='%h %s'
"Temporary build directory: $env:LAB_BUILD_ROOT"
```

The archive uses the current commit, not uncommitted changes. Review the selected
committed files before uploading them. If you intentionally change application
source, commit the reviewed change to your isolated branch, inspect and remove only
the temporary build directory shown above, and rerun this section to recreate it.
Do not remove the kubeconfig or commit credentials. This allowlist is not a
substitute for secret scanning.

## Checkpoint

You have a dedicated resource group, a reachable AKS cluster, a registry attached to
that cluster, a seeded PostgreSQL database, and a service account federated with the
managed identity. The next module builds and deploys an application to verify the
end-to-end connection.

[Next: Caldova Python](../4-python-application/) |
[Workshop home](../../index.md)
