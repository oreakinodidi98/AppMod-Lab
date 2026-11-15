---
title: Provision and configure the Azure environment
description: Provision a disposable AKS, ACR, PostgreSQL, and workload identity .
ms.topic: tutorial
parent: Module 03 - Deploy to Azure
nav_order: 1
---

## Goals

Create a new, dedicated resource group containing an AKS Automatic cluster, an Azure Container Registry (ACR), Azure Database for PostgreSQL, and a user-assigned managed identity. Configure the identity for the app implementation later in this module.

> [!WARNING]
> These steps create billable resources . Use only a subscription, region, network design, and budget approved for this workshop.

The lab uses AKS Automatic's managed networking, a public AKS API, and a public PostgreSQL endpoint restricted to the workstation and AKS outbound IPv4 addresses. The applications are exposed locally through port forwarding, not a public application route. AKS Automatic can also provision managed ingress or Gateway resources; review its defaults and associated costs with the team. 

For production, decide on private networking, egress, availability zones, monitoring, and access controls with the platform team before creating the cluster.

## 1. Prepare the terminal and select the subscription

Use the PowerShell terminal from [module 00]({{ site.baseurl }}{% link appmod-lab/0-prerequisites/prerequisite-0-1-technical.md %}).

### Restore terminal variables after a restart

If PowerShell was closed, open a new terminal inside your workshop repository and restore its path:

```powershell
$env:LAB_APP_REPO = git rev-parse --show-toplevel
if ($LASTEXITCODE -ne 0) {
    throw 'Open your workshop repository in the terminal and try again.'
}
Set-Location -LiteralPath $env:LAB_APP_REPO
```

This restores the repository path. If the Azure environment was already created,
restore its resource values
from `.envrc`; do not rerun provisioning commands just to restore variables.

```powershell
$labDirectory = Join-Path $HOME 'appmod-Student\deploy-to-azure'
New-Item -ItemType Directory -Path $labDirectory -Force | Out-Null
Set-Location -LiteralPath $labDirectory
```

Sign in to Azure and review the available subscriptions. When prompted, enter the name or ID of the subscription approved for this workshop. The command selects it and displays the subscription and tenant:

```powershell
az login
az account list --query "[].{Name:name,Id:id,Default:isDefault}" --output table
$subscription = Read-Host 'Approved subscription name or ID'
az account set --subscription $subscription
az account show --query "{Name:name,Id:id,Tenant:tenantId}" --output table
```

Confirm that the displayed subscription and tenant are correct before continuing. The next commands save their IDs and your signed-in user details as variables. Later steps use these values to scope permissions and configure the PostgreSQL administrator.

```powershell
$env:AZURE_SUBSCRIPTION_ID = az account show --query id --output tsv
$env:AZURE_TENANT_ID = az account show --query tenantId --output tsv
$subscriptionScope = "/subscriptions/$env:AZURE_SUBSCRIPTION_ID"
$env:USER_OBJECT_ID = az ad signed-in-user show --query id --output tsv
$env:USER_PRINCIPAL_NAME = az ad signed-in-user show --query userPrincipalName --output tsv
```

## 2. Set the location and resource names

Choose the approved region. Change the default names `oa-dev-sc` to your own in the form of short owner, environment, and region codes if needed. For example, `mw-dev-usw` could
represent owner `mw`, development, and West US; set `LOCATION` to the matching Azure region, such as `westus`. Use lowercase letters and numbers, with a two-character owner code, `dev`, and a two- or three-character region code.

The random suffix reduces name collisions:

```powershell
$RAND = Get-Random -Minimum 100000 -Maximum 1000000
$env:RAND = $RAND
$env:LOCATION = 'swedencentral'
$env:NAME_SUFFIX = "$RAND"
$env:NAME_PREFIX = "oa-dev-sc-$RAND"
$env:COMPACT_NAME = $env:NAME_PREFIX.Replace('-', '')
$env:RG_NAME = "rg-$env:NAME_PREFIX"
$env:AKS_NAME = "aks-$env:NAME_PREFIX"
$env:POSTGRES_SERVER_NAME = "pg-$env:NAME_PREFIX"
$env:POSTGRES_DATABASE_NAME = 'caldova'
$env:USER_ASSIGNED_IDENTITY_NAME = "mi-$env:NAME_PREFIX"
$env:ACR_NAME = "acr$env:COMPACT_NAME"
$env:MANAGED_NAMESPACE_NAME = 'caldova'
$env:API_NAME = 'caldova-api'
$env:WEB_NAME = 'caldova-web'
$env:CONFIG_NAME = 'caldova-config'
$env:SERVICE_ACCOUNT_NAME = 'caldova-api'
$env:FEDERATED_CREDENTIAL_NAME = "fic-$env:NAME_PREFIX"
$env:GATEWAY_NAMESPACE = $env:MANAGED_NAMESPACE_NAME
$env:GATEWAY_NAME = 'shared-gateway'

Write-Output "Location: $env:LOCATION"
Write-Output "Resource group: $env:RG_NAME"
Write-Output "AKS cluster: $env:AKS_NAME"
Write-Output "PostgreSQL server: $env:POSTGRES_SERVER_NAME"
Write-Output "PostgreSQL database: $env:POSTGRES_DATABASE_NAME"
Write-Output "Managed identity: $env:USER_ASSIGNED_IDENTITY_NAME"
Write-Output "Container registry: $env:ACR_NAME"
Write-Output "Namespace: $env:MANAGED_NAMESPACE_NAME"
Write-Output "API deployment: $env:API_NAME"
Write-Output "Web deployment: $env:WEB_NAME"
Write-Output "Service account: $env:SERVICE_ACCOUNT_NAME"
Write-Output "Gateway: $env:GATEWAY_NAMESPACE/$env:GATEWAY_NAME"
```


### Download the database seed and Kubernetes template

Download these two files directly from the workshop repository. The SQL file initializes PostgreSQL in Step 12, and the Kubernetes template is used by the shared deployment step. 

The commands create the destination folders inside your workshop repository.
Run them once: 


```powershell
Set-Location -LiteralPath $env:LAB_APP_REPO
New-Item -ItemType Directory -Path 'Python_app\CaldovaClinicalApi\db', 'assets\k8s' -Force | Out-Null

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Python_app/CaldovaClinicalApi/db/init.sql' `
  -OutFile 'Python_app\CaldovaClinicalApi\db\init.sql'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/k8s/caldova.yaml' `
  -OutFile 'assets\k8s\caldova.yaml'

git status --short
```

Review both files before running the SQL or deploying the template, then commit them:

```powershell
git add -- assets\k8s\caldova.yaml Python_app\CaldovaClinicalApi\db\init.sql
git commit -m "Add deployment lab files"
Set-Location -LiteralPath $labDirectory
```

## 3. Check Azure CLI and choose the AKS version

Check the CLI requirement and the default Kubernetes version available in the approved region:

```powershell
$azureCliVersion = [version]((az version --output json | ConvertFrom-Json).'azure-cli')
if ($azureCliVersion -lt [version]'2.86.0') {
    throw "Azure CLI 2.86.0 or newer is required. Installed version: $azureCliVersion"
}
Write-Output "Azure CLI version: $azureCliVersion"

$env:K8S_VERSION = (az aks get-versions --location $env:LOCATION `
    --query "values[?isDefault==``true``].version | [0]" --output tsv).Trim()
Write-Output "Default Kubernetes version in $($env:LOCATION): $env:K8S_VERSION"
```

Record the displayed Kubernetes version; we will use it in the AKS creation command.

## 4. Register the required resource providers

Provider registration prepares the subscription for resource creation. These registrations can take several minutes; wait for each one to complete before continuing:

```powershell
az provider register --namespace Microsoft.Quota --wait
az provider register --namespace Microsoft.OperationsManagement --wait
az provider register --namespace Microsoft.PolicyInsights --wait
az provider register --namespace Microsoft.Compute --wait
az provider register --namespace Microsoft.ContainerService --wait
az provider register --namespace Microsoft.Insights --wait
az provider register --namespace Microsoft.DBforPostgreSQL --wait
az provider register --namespace Microsoft.ContainerRegistry --wait
az provider register --namespace Microsoft.ManagedIdentity --wait
az provider register --namespace Microsoft.ServiceLinker --wait
az provider register --namespace Microsoft.KubernetesConfiguration --wait
az provider register --namespace Microsoft.CognitiveServices --wait
```

The preview extension and feature registrations below are not required for the standard workshop path. Run them only if your facilitator has approved the corresponding preview networking features:

```powershell
az extension add --name aks-preview
az extension add --name rdbms-connect --upgrade
az feature register --namespace Microsoft.ContainerService --name AdvancedNetworkingFlowLogsPreview
az feature register --namespace Microsoft.ContainerService --name AdvancedNetworkingL7PolicyPreview
```

## 5. Create the resource group and managed identity

Step 1, create the dedicated resource group, then create the User ssighned Managed identity :

```powershell
az group create --name $env:RG_NAME --location $env:LOCATION
Write-Output "Resource group created: $env:RG_NAME"

az identity create --name $env:USER_ASSIGNED_IDENTITY_NAME --resource-group $env:RG_NAME --location $env:LOCATION
Write-Output "Managed identity created: $env:USER_ASSIGNED_IDENTITY_NAME"
```

Retrieve the identity IDs and set the public IP address used for the PostgreSQL firewall rule:

```powershell
$env:USER_ASSIGNED_IDENTITY_ID = az identity show --name $env:USER_ASSIGNED_IDENTITY_NAME `
    --resource-group $env:RG_NAME --query id --output tsv
$env:USER_ASSIGNED_IDENTITY_CLIENT_ID = az identity show --name $env:USER_ASSIGNED_IDENTITY_NAME --resource-group $env:RG_NAME --query clientId --output tsv
$env:USER_ASSIGNED_IDENTITY_PRINCIPAL_ID = az identity show --name $env:USER_ASSIGNED_IDENTITY_NAME --resource-group $env:RG_NAME --query principalId --output tsv
$callerPublicIp = (Invoke-RestMethod -Uri 'https://api.ipify.org').Trim()

Write-Output "Managed identity client ID: $env:USER_ASSIGNED_IDENTITY_CLIENT_ID"
Write-Output "Managed identity principal ID: $env:USER_ASSIGNED_IDENTITY_PRINCIPAL_ID"
Write-Output "PostgreSQL caller firewall address: $callerPublicIp"
```
## 6. Create the PostgreSQL Flexible Server

The resource group and identity are ready from step 5. 

In secion we will run the command to create the database server, set your signed-in Entra user as its administrator, disables password authentication, and allows connections only from the workstation IP collected in step 5. 

The selected Burstable SKU and 32-GiB storage are workshop defaults; confirm they are available and approved for your region before continuing. 

Server provisioning can take several minutes.

```powershell
az postgres flexible-server create `
    --name $env:POSTGRES_SERVER_NAME `
    --resource-group $env:RG_NAME `
    --location $env:LOCATION `
    --admin-display-name $env:USER_PRINCIPAL_NAME `
    --admin-object-id $env:USER_OBJECT_ID `
    --admin-type User `
    --sku-name Standard_D2s_v3 `
    --tier GeneralPurpose `
    --version 15 `
    --storage-size 32 `
    --zonal-resiliency Disabled `
    --storage-auto-grow Enabled `
    --microsoft-entra-auth Enabled `
    --password-auth Disabled `
    --public-access $callerPublicIp
```

The `--public-access` option adds your workstation IP to the server's allowed addresses. 

Next, retrieve the server's fully qualified domain name (FQDN); the application and database tools will use it to connect:

```powershell
$env:POSTGRES_FQDN = az postgres flexible-server show `
  --resource-group $env:RG_NAME `
  --name $env:POSTGRES_SERVER_NAME `
  --query fullyQualifiedDomainName `
  --output tsv
Write-Output "PostgreSQL FQDN: $env:POSTGRES_FQDN"
```

Create the `caldova` database inside the new server. 

The server and database are separate Azure resources, so this step must follow successful server creation:

```powershell
az postgres flexible-server db create `
  --resource-group $env:RG_NAME `
  --server-name $env:POSTGRES_SERVER_NAME `
  --name $env:POSTGRES_DATABASE_NAME
Write-Output "PostgreSQL database created: $env:POSTGRES_DATABASE_NAME"
```

Capture the database resource ID for later database authorization and identity configuration steps:

```powershell
$env:POSTGRES_DATABASE_ID = az postgres flexible-server db show `
  --resource-group $env:RG_NAME `
  --server-name $env:POSTGRES_SERVER_NAME `
  --name $env:POSTGRES_DATABASE_NAME `
  --query id `
  --output tsv
Write-Output "PostgreSQL database ID: $env:POSTGRES_DATABASE_ID"
```

## 7. Create Key Vault and grant access

This step create a Key Vault so that the AKS Secrets Store add-on can use it in the following step. 

The vault uses Azure RBAC for access control allowing the later application steps to retrieve approved secrets without putting them in source code or Kubernetes manifests.

We will create the vault in the same dedicated resource group, then retrieve its resource ID and URI. 

The ID is used to scope role assignments; the URI identifies the vault endpoint:

```powershell
$env:KV_NAME = "kv-$env:NAME_PREFIX"
Write-Output "Creating Key Vault: $env:KV_NAME"
az keyvault create `
  --name $env:KV_NAME `
  --resource-group $env:RG_NAME `
  --location $env:LOCATION `
  --enable-rbac-authorization true `
  --sku standard
Write-Output "Azure Key Vault $env:KV_NAME created in resource group $env:RG_NAME"
$env:KV_ID = az keyvault show `
  --name $env:KV_NAME `
  --query id --output tsv
$env:KV_URI = az keyvault show `
  --name $env:KV_NAME `
  --query properties.vaultUri --output tsv
Write-Output "Key Vault resource ID: $env:KV_ID"
Write-Output "Key Vault URI: $env:KV_URI"
```

Give the managed identity permission to read secrets from this vault:

```powershell
az role assignment create `
  --role "Key Vault Secrets User" `
  --assignee $env:USER_ASSIGNED_IDENTITY_PRINCIPAL_ID `
  --scope $env:KV_ID
```

If a later exercise retrieves a certificate from Key Vault, also grant the managed identity certificate access:

```powershell
az role assignment create `
  --role "Key Vault Certificate User" `
  --assignee $env:USER_ASSIGNED_IDENTITY_PRINCIPAL_ID `
  --scope $env:KV_ID
```

The signed-in user needs permission to add the lab's test secret or certificate.

This assigns the Key Vault Administrator role at the vault scope, this is only used for demo purposes:

```powershell
az role assignment create `
  --role "Key Vault Administrator" `
  --assignee $env:USER_OBJECT_ID `
  --scope $env:KV_ID
Write-Output "Key Vault roles assigned successfully."
```

## 8. Create the AKS cluster

In this step we will create an AKS automatic cluster, enabling the Key Vault Secrets Store
CSI add-on with secret rotation, as required for AKS Automatic. 

The add-on creates an identity that allows the cluster to grants access to this vault. 

Workload identity and the OIDC issuer are enabled for the application to PostgreSQL connection; Gateway API and ACNS provide the cluster features used by the later deployment steps.

```powershell
az aks create `
--resource-group $env:RG_NAME `
--name $env:AKS_NAME `
--location $env:LOCATION `
--kubernetes-version $env:K8S_VERSION `
--sku automatic `
--enable-hosted-system `
--enable-managed-identity `
--enable-workload-identity `
--enable-oidc-issuer `
--enable-addons azure-keyvault-secrets-provider `
--enable-secret-rotation `
--enable-gateway-api `
--enable-acns `
--no-ssh-key
```
> Provisioning can take several minutes.

Wait for cluster creation to succeed before retrieving credentials. If the command fails, review the error and check the cluster's provisioning state before retrying:

```powershell
az aks show --resource-group $env:RG_NAME --name $env:AKS_NAME `
  --query "{name:name,provisioningState:provisioningState}" --output json
```

If a cluster exists, review its state before taking further action. A `ResourceNotFound` response means no cluster with that name was found.

Save the credentials to a dedicated workshop kubeconfig and set `KUBECONFIG` so subsequent `kubectl` commands use this cluster. Keep this path rather than overwriting your default kubeconfig; Step 13 saves it for later sessions.

```powershell
$env:AKS_KUBECONFIG_PATH = Join-Path $labDirectory "$env:AKS_NAME.kubeconfig"
az aks get-credentials `
  --resource-group $env:RG_NAME `
  --name $env:AKS_NAME `
  --file $env:AKS_KUBECONFIG_PATH
$env:KUBECONFIG = $env:AKS_KUBECONFIG_PATH
Write-Output "AKS credentials added to: $env:AKS_KUBECONFIG_PATH"
```

## 9. Create the container registry and grant AKS pull access

The AKS cluster is ready. Create an Azure Container Registry (ACR) for the
application images, with its administrator account disabled. Then grant the
cluster's kubelet identity the `AcrPull` role so AKS can download those images
without registry credentials in the manifests.

Continue in the same PowerShell terminal used for the earlier steps. The
commands reuse the resource names and settings already stored in environment
variables:

```powershell
Write-Output "Creating Azure Container Registry: $env:ACR_NAME"
az acr create `
  --resource-group $env:RG_NAME `
  --name $env:ACR_NAME `
  --sku Standard `
  --location $env:LOCATION `
  --admin-enabled false

$env:ACR_ID = az acr show `
  --name $env:ACR_NAME `
  --resource-group $env:RG_NAME `
  --query id `
  --output tsv

$env:ACR_LOGIN_SERVER = az acr show `
  --name $env:ACR_NAME `
  --resource-group $env:RG_NAME `
  --query loginServer `
  --output tsv
Write-Output "Container Registry: $env:ACR_LOGIN_SERVER"

$env:KUBELET_OBJECT_ID = az aks show `
  --resource-group $env:RG_NAME `
  --name $env:AKS_NAME `
  --query identityProfile.kubeletidentity.objectId `
  --output tsv
Write-Output "Kubelet identity object ID: $env:KUBELET_OBJECT_ID"

az role assignment create `
  --assignee-object-id $env:KUBELET_OBJECT_ID `
  --assignee-principal-type ServicePrincipal `
  --role "AcrPull" `
  --scope $env:ACR_ID
Write-Output "ACR pull role assignment requested. Allow time for permission propagation before deploying images."
```

Role assignments can take several minutes to propagate. If an image pull is denied immediately after this step, wait and retry before changing the registry permissions.

## 10. Configure AKS identities for the application

Enabling `azure-keyvault-secrets-provider` in Step 8 created a separate managed
identity for the Secrets Store add-on. Retrieve its client ID for a later
`SecretProviderClass` and its object ID for Azure RBAC. The Key Vault resource
ID was captured as `$env:KV_ID` in Step 7, so reuse it as the role-assignment scope.

```powershell
$env:KEYVAULT_ADDON_CLIENT_ID = az aks show `
  --resource-group $env:RG_NAME `
  --name $env:AKS_NAME `
  --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId `
  --output tsv

$env:KEYVAULT_ADDON_OBJECT_ID = az aks show `
  --resource-group $env:RG_NAME `
  --name $env:AKS_NAME `
  --query addonProfiles.azureKeyvaultSecretsProvider.identity.objectId `
  --output tsv
Write-Output "Key Vault add-on identity client ID: $env:KEYVAULT_ADDON_CLIENT_ID"

az role assignment create `
  --assignee-object-id $env:KEYVAULT_ADDON_OBJECT_ID `
  --assignee-principal-type ServicePrincipal `
  --role "Key Vault Secrets User" `
  --scope $env:KV_ID
Write-Output "Key Vault Secrets User role assignment requested for the AKS add-on identity."
```

This role lets the add-on retrieve secrets from Key Vault. Allow time for the role assignment to propagate before testing a mount.

The application uses a different identity: the user-assigned managed identity created in Step 5. A federated credential connects that identity to the Kubernetes service account. The namespace and service account names were set in step 2, and the cluster's OIDC issuer was enabled in Step 8.

Retrieve the issuer and construct the federation subject from the exact
namespace and service account names:

```powershell
$env:AKS_OIDC_ISSUER = az aks show `
  --resource-group $env:RG_NAME `
  --name $env:AKS_NAME `
  --query oidcIssuerProfile.issuerUrl `
  --output tsv
$workloadSubject = 'system:serviceaccount:' + $env:MANAGED_NAMESPACE_NAME + ':' + $env:SERVICE_ACCOUNT_NAME
Write-Output "Workload identity subject: $workloadSubject"
```

Create the federated credential for that subject:

```powershell
az identity federated-credential create `
  --resource-group $env:RG_NAME `
  --identity-name $env:USER_ASSIGNED_IDENTITY_NAME `
  --name $env:FEDERATED_CREDENTIAL_NAME `
  --issuer $env:AKS_OIDC_ISSUER `
  --subject $workloadSubject `
  --audiences api://AzureADTokenExchange
```

Create a managed namespace before adding the service account. Its quotas cap the total CPU and memory requests and limits across the namespace; they do not reserve capacity. The CPU quotas below accommodate the API and web pods, including temporary extra pods during rolling updates. One API pod and one web pod request `350m` of CPU in total and have CPU limits totaling `2` cores.

Review the quotas before running additional workloads alongside them.

Namespace-local ingress allows pod traffic from the same namespace, while unrestricted egress lets the workloads reach PostgreSQL and Azure services.

If you later use a Gateway in another namespace, review the ingress policy with the platform owner first.

If you already created this namespace using `kubectl`, do not run the command unchanged: managed namespaces do not adopt existing namespaces by default.

Review its workloads, quotas, and network policies before explicitly choosing an [adoption policy](https://learn.microsoft.com/cli/azure/aks/namespace#az-aks-namespace-add).

```powershell
az aks namespace add `
  --resource-group $env:RG_NAME `
  --cluster-name $env:AKS_NAME `
  --name $env:MANAGED_NAMESPACE_NAME `
  --cpu-request 1000m `
  --cpu-limit 4 `
  --memory-request 4Gi `
  --memory-limit 8Gi `
  --ingress-policy AllowSameNamespace `
  --egress-policy AllowAll
```

Wait for namespace creation to succeed, then inspect its quotas and network policies:

```powershell
kubectl get namespace $env:MANAGED_NAMESPACE_NAME
kubectl get resourcequota,networkpolicy --namespace $env:MANAGED_NAMESPACE_NAME
```

Create and annotate the service account in that namespace with the user-assigned identity's client ID:

```powershell
kubectl create serviceaccount $env:SERVICE_ACCOUNT_NAME `
  --namespace $env:MANAGED_NAMESPACE_NAME
kubectl annotate serviceaccount $env:SERVICE_ACCOUNT_NAME `
  --namespace $env:MANAGED_NAMESPACE_NAME `
  "azure.workload.identity/client-id=$env:USER_ASSIGNED_IDENTITY_CLIENT_ID"
```

The pod template in the shared deployment step labels the API pod for the Workload Identity webhook. Keep the federation subject, namespace, service account, and annotation aligned; a mismatch prevents the pod from exchanging its token for an Azure access token.

## 11. Allow AKS egress to PostgreSQL

The PostgreSQL firewall currently allows the workstation IP. AKS needs its ownmnetwork access so the application pods can connect to the database. This step discovers the cluster's outbound type and public IP resources, then adds a single-IP firewall rule for each address. It does not open PostgreSQL to all Azure services or to a broad IP range.

Continue in the same PowerShell terminal. The commands in this step discover the AKS outbound IP addresses; the following step creates one firewall rule for each address.

The local PowerShell variables use lower camel case; shared environment settings use `$env:` names in upper snake case.

### Find the cluster's outbound IP addresses

First inspect the AKS outbound type and node resource group. For a load-balancer
outbound type, the profile provides the effective public IP resource IDs. For a
managed NAT gateway, the commands find the gateway IDs attached to the AKS
subnets, then retrieve their public IP resource IDs. An unsupported outbound
type stops here so you can ask the network administrator for an approved rule
instead of opening access broadly.

```powershell
$aksNetworkProfileJson = az aks show `
  --resource-group $env:RG_NAME `
  --name $env:AKS_NAME `
  --query "{outboundType:networkProfile.outboundType,nodeResourceGroup:nodeResourceGroup,loadBalancerPublicIpIds:networkProfile.loadBalancerProfile.effectiveOutboundIPs[].id}" `
  --output json
if ($LASTEXITCODE -ne 0) {
  throw "Unable to inspect the AKS outbound network profile."
}
$aksNetworkProfile = $aksNetworkProfileJson | ConvertFrom-Json

$aksOutboundIpResourceIds = @()
switch ($aksNetworkProfile.outboundType) {
  "loadBalancer" {
    $aksOutboundIpResourceIds = @($aksNetworkProfile.loadBalancerPublicIpIds) | Where-Object { $_ }
  }
  "managedNATGateway" {
    $natGatewayResourceIds = @(
      az network vnet list `
        --resource-group $aksNetworkProfile.nodeResourceGroup `
        --query "[].subnets[].natGateway.id" `
        --output tsv
    ) | Where-Object { $_ } | Sort-Object -Unique
    if ($LASTEXITCODE -ne 0) {
      throw "Unable to inspect NAT gateways attached to the AKS subnets."
    }

    foreach ($natGatewayResourceId in $natGatewayResourceIds) {
      $aksOutboundIpResourceIds += @(
        az network nat gateway show `
          --ids $natGatewayResourceId `
          --query "publicIpAddresses[].id" `
          --output tsv
      ) | Where-Object { $_ }
      if ($LASTEXITCODE -ne 0) {
        throw "Unable to inspect AKS NAT gateway '$natGatewayResourceId'."
      }
    }
  }
  default {
    throw "AKS outbound type '$($aksNetworkProfile.outboundType)' is not supported for PostgreSQL firewall configuration."
  }
}

if ($aksOutboundIpResourceIds.Count -eq 0) {
  throw "AKS did not report any effective outbound public IP resources."
}

$aksOutboundIps = @()
foreach ($publicIpResourceId in $aksOutboundIpResourceIds) {
  $aksOutboundIp = az network public-ip show `
    --ids $publicIpResourceId `
    --query ipAddress `
    --output tsv
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to resolve AKS outbound public IP resource '$publicIpResourceId'."
  }
  if ($aksOutboundIp) {
    $aksOutboundIps += $aksOutboundIp
  }
}

if ($aksOutboundIps.Count -eq 0) {
  throw "Unable to resolve the effective AKS outbound public IP addresses."
}

Write-Output "AKS outbound IP addresses: $($aksOutboundIps -join ', ')"
```

### Create firewall rules for those addresses

The following loop creates one firewall rule for each unique AKS egress IP.
This keeps firewall access limited to the addresses the cluster actually uses.
If the cluster's outbound addresses change later, repeat this discovery and
update the rules with the facilitator.

The `foreach` loop is needed because Azure can assign more than one outbound IP.
The resource IDs and addresses are kept in lower-camel-case variables; the
PostgreSQL server and resource group continue to use the environment variables
set in the earlier steps.

```powershell
$firewallRuleIndex = 1
foreach ($aksOutboundIp in $aksOutboundIps | Sort-Object -Unique) {
  az postgres flexible-server firewall-rule create `
    --resource-group $env:RG_NAME `
    --server-name $env:POSTGRES_SERVER_NAME `
    --name "AllowAksEgress$firewallRuleIndex" `
    --start-ip-address $aksOutboundIp `
    --end-ip-address $aksOutboundIp
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to allow AKS outbound IP '$aksOutboundIp' through the PostgreSQL firewall."
  }
  $firewallRuleIndex++
}
```

## 12. Initialize the database and authorize the app identity

Firewall rules control which hosts can reach PostgreSQL; they do not grant a
database identity permission to read or change data. Next, create a PostgreSQL
principal that maps to the user-assigned managed identity, initialize the
`pharmacy` schema and sample data, and grant the app identity the database
permissions its API needs.

The seed file is in the student's workshop repository. Set its path from
`LAB_APP_REPO` rather than `$PSScriptRoot`, which is only populated when a
PowerShell script file is running:

```powershell
$databaseBootstrapFile = Join-Path $env:LAB_APP_REPO 'Python_app\CaldovaClinicalApi\db\init.sql'
if (-not (Test-Path $databaseBootstrapFile)) {
  throw "Database bootstrap file not found: $databaseBootstrapFile"
}
```

The next commands build the principal and grant SQL using the identity name and
database name from the earlier steps. The grants allow the application to use
the schema, read and update its tables, and use sequences; default privileges
also apply to tables and sequences created later:

```powershell
$databaseRoleSql = @"
DO `$`$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_roles
    WHERE rolname = '$env:USER_ASSIGNED_IDENTITY_NAME'
  ) THEN
    PERFORM pg_catalog.pgaadauth_create_principal_with_oid(
      '$env:USER_ASSIGNED_IDENTITY_NAME',
      '$env:USER_ASSIGNED_IDENTITY_PRINCIPAL_ID',
      'service',
      false,
      false
    );
  END IF;
END
`$`$;
"@
$databaseGrantSql = @"
GRANT CONNECT ON DATABASE $env:POSTGRES_DATABASE_NAME TO "$env:USER_ASSIGNED_IDENTITY_NAME";
GRANT USAGE ON SCHEMA pharmacy TO "$env:USER_ASSIGNED_IDENTITY_NAME";
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA pharmacy TO "$env:USER_ASSIGNED_IDENTITY_NAME";
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA pharmacy TO "$env:USER_ASSIGNED_IDENTITY_NAME";
ALTER DEFAULT PRIVILEGES IN SCHEMA pharmacy GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO "$env:USER_ASSIGNED_IDENTITY_NAME";
ALTER DEFAULT PRIVILEGES IN SCHEMA pharmacy GRANT USAGE, SELECT ON SEQUENCES TO "$env:USER_ASSIGNED_IDENTITY_NAME";
"@
```

Run the SQL with the `rdbms-connect` extension installed in Step 4. The role and
grant SQL are written to temporary files because passing multiline SQL through
`--querytext` can lose content or quotation marks in PowerShell. Create the
identity in the `postgres` database, then initialize the application database
and apply its grants.

The short-lived Microsoft Entra token is passed to Azure CLI as an argument and
may be visible to local process inspection. Do not share command traces or the
token. The temporary files and environment token are removed in `finally`,
including when an execution fails.

```powershell
$roleFile = $null
$grantFile = $null
try {
  $roleFile = New-TemporaryFile
  $grantFile = New-TemporaryFile
  Set-Content -LiteralPath $roleFile -Value $databaseRoleSql -Encoding utf8
  Set-Content -LiteralPath $grantFile -Value $databaseGrantSql -Encoding utf8

  $env:PGPASSWORD = az account get-access-token `
    --resource-type oss-rdbms `
    --query accessToken `
    --output tsv
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($env:PGPASSWORD)) {
    throw "Unable to acquire a Microsoft Entra access token for PostgreSQL."
  }

  az postgres flexible-server execute `
    --name $env:POSTGRES_SERVER_NAME `
    --admin-user $env:USER_PRINCIPAL_NAME `
    --admin-password $env:PGPASSWORD `
    --database-name postgres `
    --file-path $roleFile `
    --output none
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to create or verify the workload identity PostgreSQL principal."
  }

  az postgres flexible-server execute `
    --name $env:POSTGRES_SERVER_NAME `
    --admin-user $env:USER_PRINCIPAL_NAME `
    --admin-password $env:PGPASSWORD `
    --database-name $env:POSTGRES_DATABASE_NAME `
    --file-path $databaseBootstrapFile `
    --output none
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to initialize the PostgreSQL schema from '$databaseBootstrapFile'."
  }

  az postgres flexible-server execute `
    --name $env:POSTGRES_SERVER_NAME `
    --admin-user $env:USER_PRINCIPAL_NAME `
    --admin-password $env:PGPASSWORD `
    --database-name $env:POSTGRES_DATABASE_NAME `
    --file-path $grantFile `
    --output none
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to grant the workload identity access to the PostgreSQL schema."
  }
}
finally {
  Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
  if ($roleFile) { Remove-Item -LiteralPath $roleFile -ErrorAction Continue }
  if ($grantFile) { Remove-Item -LiteralPath $grantFile -ErrorAction Continue }
}
```

If you already initialized the schema successfully while troubleshooting, the
seed uses `CREATE ... IF NOT EXISTS` and conflict-safe inserts, so it can be
run again. Review any existing database changes before retrying.

## 13. Save the environment values

Save the non-secret resource names, IDs, and connection details in `.envrc` so
you can refer to them later without rerunning the setup commands. This file is
gitignored. The Key Vault identity and scope are written using the variable
names expected by the later lab steps.

```powershell
$postgresAksEgressIps = $aksOutboundIps -join ','
$env:BUILD_ROOT = Join-Path $env:TEMP "caldova-build-$env:NAME_SUFFIX"
$env:AKS_NODE_RESOURCE_GROUP = az aks show `
    --resource-group $env:RG_NAME `
    --name $env:AKS_NAME `
    --query nodeResourceGroup `
    --output tsv
$envrcContent = @"
export LAB_APP_REPO=$env:LAB_APP_REPO
export AZURE_SUBSCRIPTION_ID=$env:AZURE_SUBSCRIPTION_ID
export AZURE_TENANT_ID=$env:AZURE_TENANT_ID
export RAND=$env:RAND
export NAME_SUFFIX=$env:NAME_SUFFIX
export NAME_PREFIX=$env:NAME_PREFIX
export KV_NAME=$env:KV_NAME
export LOCATION=$env:LOCATION
export RG_NAME=$env:RG_NAME
export AKS_NAME=$env:AKS_NAME
export AKS_NODE_RESOURCE_GROUP=$env:AKS_NODE_RESOURCE_GROUP
export K8S_VERSION=$env:K8S_VERSION
export AKS_KUBECONFIG_PATH=$env:AKS_KUBECONFIG_PATH
export BUILD_ROOT=$env:BUILD_ROOT
export ACR_NAME=$env:ACR_NAME
export ACR_ID=$env:ACR_ID
export ACR_LOGIN_SERVER=$env:ACR_LOGIN_SERVER
export KUBELET_OBJECT_ID=$env:KUBELET_OBJECT_ID
export USER_ASSIGNED_IDENTITY_NAME=$env:USER_ASSIGNED_IDENTITY_NAME
export USER_ASSIGNED_IDENTITY_ID=$env:USER_ASSIGNED_IDENTITY_ID
export USER_ASSIGNED_IDENTITY_CLIENT_ID=$env:USER_ASSIGNED_IDENTITY_CLIENT_ID
export USER_ASSIGNED_IDENTITY_PRINCIPAL_ID=$env:USER_ASSIGNED_IDENTITY_PRINCIPAL_ID
export FEDERATED_CREDENTIAL_NAME=$env:FEDERATED_CREDENTIAL_NAME
export AKS_OIDC_ISSUER=$env:AKS_OIDC_ISSUER
export POSTGRES_DATABASE_ID=$env:POSTGRES_DATABASE_ID
export POSTGRES_SERVER_NAME=$env:POSTGRES_SERVER_NAME
export POSTGRES_DATABASE_NAME=$env:POSTGRES_DATABASE_NAME
export POSTGRES_FQDN=$env:POSTGRES_FQDN
export POSTGRES_CALLER_FIREWALL_IP=$callerPublicIp
export POSTGRES_AKS_EGRESS_IPS=$postgresAksEgressIps
export MANAGED_NAMESPACE_NAME=$env:MANAGED_NAMESPACE_NAME
export API_NAME=$env:API_NAME
export WEB_NAME=$env:WEB_NAME
export CONFIG_NAME=$env:CONFIG_NAME
export SERVICE_ACCOUNT_NAME=$env:SERVICE_ACCOUNT_NAME
export GATEWAY_NAMESPACE=$env:GATEWAY_NAMESPACE
export GATEWAY_NAME=$env:GATEWAY_NAME
export KEYVAULT_ADDON_CLIENT_ID=$env:KEYVAULT_ADDON_CLIENT_ID
export KEYVAULT_ADDON_OBJECT_ID=$env:KEYVAULT_ADDON_OBJECT_ID
export KV_ID=$env:KV_ID
"@
$envrcPath = Join-Path $env:LAB_APP_REPO '.envrc'
$envrcContent | Out-File -FilePath $envrcPath -Encoding utf8
Write-Output "Environment values saved to: $envrcPath"
```

### Checkpoint

You now have a dedicated resource group, a reachable AKS cluster, ACR pull
access for the cluster, a seeded PostgreSQL database, and a Kubernetes service
account federated with the user-assigned managed identity. The `.envrc` file
records the resource values for the remaining modules. Keep this PowerShell
terminal open so the environment variables remain available.

[Next: deploy Python]({{ site.baseurl }}{% link appmod-lab/3-deploy-to-azure/deploy-to-azure-3-2-python.md %}) |
[Module 03 home]({{ site.baseurl }}{% link appmod-lab/3-deploy-to-azure/index.md %}) |
[Workshop home]({{ site.baseurl }}{% link index.md %})
