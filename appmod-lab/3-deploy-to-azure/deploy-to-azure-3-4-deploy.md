---
title: Build and deploy to Azure
description: Deploy Caldova on AKS and verify database-backed behavior.
ms.topic: tutorial
parent: Module 03 - Deploy to Azure
nav_order: 4
---

## Before you start

Complete [environment setup]({{ site.baseurl }}{% link appmod-lab/3-deploy-to-azure/deploy-to-azure-3-1-environment.md %}) and choose the Python or Java
application in the [Python path]({{ site.baseurl }}{% link appmod-lab/3-deploy-to-azure/deploy-to-azure-3-2-python.md %}) or
[Java path]({{ site.baseurl }}{% link appmod-lab/3-deploy-to-azure/deploy-to-azure-3-3-java.md %}).

Use the same PowerShell terminal from environment setup and keep the values in
`.envrc` available. Both application paths build, scan, and publish their images in their own exercises, then start here at step 2 with the verified image digests. Step 1 is also used by the source-modernization exercise. The commands operate only on your dedicated resource group, registry, cluster, and namespace.

If you are switching implementations, stop the old port forwards first. The deployment replaces their target pods, so you must start new forwards afterward.

## 1. Build and identify the images

Check the current subscription and the two Dockerfiles before building. Confirm that the displayed subscription ID matches the workshop subscription, and review the build folders for sensitive files before uploading them.

```powershell
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$env:API_IMAGE = $null
$env:WEB_IMAGE = $null
az account show --query "{Name:name,Id:id}" --output table
"Workshop subscription ID: $env:AZURE_SUBSCRIPTION_ID"
Get-Item (Join-Path $env:API_BUILD_CONTEXT 'Dockerfile')
Get-Item (Join-Path $env:WEB_BUILD_CONTEXT 'Dockerfile')
```

Stop if the subscription is wrong or either Dockerfile is missing. Next,
build both images in your registry using a new tag:

```powershell
$tag = "lab-$([guid]::NewGuid().ToString('N').Substring(0, 12))"
$apiTag = '{0}:{1}' -f $env:API_IMAGE_REPOSITORY, $tag
$webTag = '{0}:{1}' -f $env:WEB_IMAGE_REPOSITORY, $tag
az acr build --resource-group $env:RG_NAME --registry $env:ACR_NAME `
    --file Dockerfile --image $apiTag $env:API_BUILD_CONTEXT
az acr build --resource-group $env:RG_NAME --registry $env:ACR_NAME `
    --file Dockerfile --image $webTag $env:WEB_BUILD_CONTEXT
```

Retrieve each image's digest and save the image references. Unlike tags,
digests identify a specific image. Each displayed reference should end in
`@sha256:` followed by 64 hexadecimal characters.

```powershell
$apiDigest = (az acr manifest show-metadata --registry $env:ACR_NAME `
    --name $apiTag --query digest --output tsv).Trim()
$webDigest = (az acr manifest show-metadata --registry $env:ACR_NAME `
    --name $webTag --query digest --output tsv).Trim()
$env:API_IMAGE = '{0}/{1}@{2}' -f $env:ACR_LOGIN_SERVER, $env:API_IMAGE_REPOSITORY, $apiDigest
$env:WEB_IMAGE = '{0}/{1}@{2}' -f $env:ACR_LOGIN_SERVER, $env:WEB_IMAGE_REPOSITORY, $webDigest
"API image: $env:API_IMAGE"
"Web image: $env:WEB_IMAGE"
```

If a command fails or either image reference is incomplete, stop and inspect the error and any image the build created before retrying or troubleshooting with Github Copilot.


## 2. Configure and deploy

The ConfigMap contains non-secret connection settings. The API pod receives its
managed identity configuration through the service account and workload identity
webhook; it does not receive a database password. Environment setup downloads
the template to `assets/k8s/caldova.yaml` in your workshop repository.

You will create a Deployment and a Service YAML file for each application,
then create a ConfigMap and apply the files to AKS. Choose whether to create
the files yourself or use GitHub Copilot.

### Check your workshop settings

We will first display the target and the values needed for deployment. Check the subscription, kubeconfig, cluster context, and namespace against your environment setup. The image references must be the scanned digest references from your Python or Java path.

```powershell
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
az account show --query "{Name:name,Id:id}" --output table
"Workshop subscription ID: $env:AZURE_SUBSCRIPTION_ID"
"Workshop cluster: $env:AKS_NAME"
"Kubeconfig: $env:KUBECONFIG"
kubectl config current-context
"Namespace: $env:MANAGED_NAMESPACE_NAME"
"ConfigMap: $env:CONFIG_NAME"
"Service account: $env:SERVICE_ACCOUNT_NAME"
"API deployment and service: $env:API_NAME"
"Web deployment and service: $env:WEB_NAME"
"PostgreSQL host: $env:POSTGRES_FQDN"
"PostgreSQL database: $env:POSTGRES_DATABASE_NAME"
"PostgreSQL identity: $env:USER_ASSIGNED_IDENTITY_NAME"
"API image: $env:API_IMAGE"
"Web image: $env:WEB_IMAGE"
"Template: $(Join-Path $env:LAB_APP_REPO 'assets\k8s\caldova.yaml')"
```

Stop if any value is missing or the target is wrong. Do not share tokens, passwords, kubeconfig contents, or sensitive logs with Github Copilot.

### Check Workload Identity

[Environment setup]({{ site.baseurl }}{% link appmod-lab/3-deploy-to-azure/deploy-to-azure-3-1-environment.md %})
already enabled the AKS OIDC issuer and Workload Identity, created the
managed namespace and annotated service account, configured federation,
and granted the managed identity access inside PostgreSQL. It also connected
`kubectl` using a dedicated kubeconfig. Azure RBAC alone does not create the
PostgreSQL principal.

Check the existing configuration rather than creating another namespace or
overwriting your default kubeconfig:

```powershell
az aks show --resource-group $env:RG_NAME --name $env:AKS_NAME `
    --query "{issuer:oidcIssuerProfile.issuerUrl,workloadIdentity:securityProfile.workloadIdentity.enabled}" `
    --output json
az identity federated-credential show --resource-group $env:RG_NAME `
    --identity-name $env:USER_ASSIGNED_IDENTITY_NAME `
    --name $env:FEDERATED_CREDENTIAL_NAME `
    --query "{issuer:issuer,subject:subject,audiences:audiences}" --output json
kubectl describe serviceaccount $env:SERVICE_ACCOUNT_NAME `
    --namespace $env:MANAGED_NAMESPACE_NAME
"Expected subject: system:serviceaccount:$env:MANAGED_NAMESPACE_NAME`:$env:SERVICE_ACCOUNT_NAME"
"Expected identity client ID: $env:USER_ASSIGNED_IDENTITY_CLIENT_ID"
```

Confirm Workload Identity is enabled, the issuers match, the audience is
`api://AzureADTokenExchange`, the subject matches your namespace and service
account, and the service account annotation contains the expected client ID.
If something is missing or different, stop and review
[AKS identity setup]({{ site.baseurl }}{% link appmod-lab/3-deploy-to-azure/deploy-to-azure-3-1-environment.md %}#10-configure-aks-identities-for-the-application)
and [database authorization]({{ site.baseurl }}{% link appmod-lab/3-deploy-to-azure/deploy-to-azure-3-1-environment.md %}#12-initialize-the-database-and-authorize-the-app-identity).

### Create the Deployment and Service files

Choose **one** of the following options. Both create four files under
`assets/k8s/workshop` in your repository. If the files already exist, review
them before replacing anything.

| File | Resource |
| --- | --- |
| `api-deployment.yaml` | API Deployment |
| `api-service.yaml` | API Service |
| `web-deployment.yaml` | Web Deployment |
| `web-service.yaml` | Web Service |

#### Option 1: Create the files yourself

In VS Code, open `assets/k8s/caldova.yaml`. It contains four YAML documents,
separated by `---`, in the same order as the table. Create the folder
`assets/k8s/workshop`, then create each file and copy its corresponding
document into it. Do not copy the `---` separators.

Replace the placeholders in the four files with the values displayed in
**Check your workshop settings**:

| Placeholder | Workshop value |
| --- | --- |
| `__API_NAME__` | API deployment and service |
| `__WEB_NAME__` | Web deployment and service |
| `__SERVICE_ACCOUNT__` | Service account |
| `__CONFIG_NAME__` | ConfigMap |
| `__API_IMAGE__` | API image digest reference |
| `__WEB_IMAGE__` | Web image digest reference |

Save the files. The Deployments describe the pods; the Services route traffic
to them using matching labels.

#### Option 2: Create the files with Copilot

In VS Code GitHub Copilot Chat, select agent mode and describe the task in your
own words. Ask it to create the four files in the table using the existing
`assets/k8s/caldova.yaml` as a reference and the workshop values displayed
above. Review any information before sharing it under your organization's
policies.

Guide Copilot to preserve the template's one replica per Deployment, matching
Service selectors, image digests, ports, resource limits, probes, security
settings, API service account, and `azure.workload.identity/use: "true"` pod
label. The API uses `/live` for liveness and `/health` for database readiness.
Ask it to put your actual workshop values in the files and show them for
review, not to apply them yet.

### Review and apply the files

Review all four files, regardless of which option you chose. Make sure no
`__PLACEHOLDER__` values remain, the image references match the scanned
digests, the Services select the right pods, and the API uses the existing
service account and workload identity label. The workshop starts with
**one replica** per app; module 04 explores scaling.

First, create or update the ConfigMap. It contains non-secret database and
API connection settings:

```powershell
kubectl create configmap $env:CONFIG_NAME --namespace $env:MANAGED_NAMESPACE_NAME `
    --from-literal=DATA_MODE=database `
    --from-literal=DATABASE_AUTH_MODE=entra `
    "--from-literal=DATABASE_HOST=$env:POSTGRES_FQDN" `
    --from-literal=DATABASE_PORT=5432 `
    "--from-literal=DATABASE_NAME=$env:POSTGRES_DATABASE_NAME" `
    "--from-literal=DATABASE_USER=$env:USER_ASSIGNED_IDENTITY_NAME" `
    "--from-literal=CALDOVA_API_URL=http://$env:API_NAME" `
    --dry-run=client --output yaml |
    kubectl apply --namespace $env:MANAGED_NAMESPACE_NAME --filename -
```

Apply the four reviewed files to the workshop namespace. Their Deployments
already contain the digest references, so a separate `kubectl set image`
command is not needed.

```powershell
$manifestDir = Join-Path $env:LAB_APP_REPO 'assets\k8s\workshop'
kubectl apply --namespace $env:MANAGED_NAMESPACE_NAME --filename (Join-Path $manifestDir 'api-deployment.yaml')
kubectl apply --namespace $env:MANAGED_NAMESPACE_NAME --filename (Join-Path $manifestDir 'api-service.yaml')
kubectl apply --namespace $env:MANAGED_NAMESPACE_NAME --filename (Join-Path $manifestDir 'web-deployment.yaml')
kubectl apply --namespace $env:MANAGED_NAMESPACE_NAME --filename (Join-Path $manifestDir 'web-service.yaml')
```

Do not replace a failed database connection with demo data or bypass readiness
checks. If a command fails, stop and investigate before continuing.

### Check the deployment

After either option, return to the original setup terminal. These commands
wait for both rollouts and list the deployments, pods, and services:

```powershell
kubectl rollout status "deployment/$env:API_NAME" --namespace $env:MANAGED_NAMESPACE_NAME --timeout=10m
kubectl rollout status "deployment/$env:WEB_NAME" --namespace $env:MANAGED_NAMESPACE_NAME --timeout=10m
kubectl get deployments,pods,services --namespace $env:MANAGED_NAMESPACE_NAME
```

Confirm that both deployments show `1/1` ready. Check that the deployed images and
API service account match your workshop settings:

```powershell
kubectl get deployments $env:API_NAME $env:WEB_NAME `
    --namespace $env:MANAGED_NAMESPACE_NAME --output wide
kubectl get deployment $env:API_NAME --namespace $env:MANAGED_NAMESPACE_NAME `
    --output 'jsonpath={.spec.template.spec.serviceAccountName}'
```

Compare these results with the displayed digest references and service account.
Continue to the database-backed checks in steps 3 and 4 only after the
rollouts succeed.

The API uses `/live` for startup and liveness and `/health` for database readiness.
The web probe checks its own HTTP endpoint; it does not prove that the API or
database is healthy. Image and application ports in the template are the fixed
contracts of these sample Dockerfiles, not Azure environment identifiers.

For the **Java** images, you can also check the API and rendered web page from
inside their pods. These commands use `wget`, which is available in the Java
images; use steps 3 and 4 for the Python images instead.

```powershell
kubectl exec "deployment/$env:API_NAME" --namespace $env:MANAGED_NAMESPACE_NAME -- wget -qO- http://127.0.0.1:8000/live
kubectl exec "deployment/$env:API_NAME" --namespace $env:MANAGED_NAMESPACE_NAME -- wget -qO- http://127.0.0.1:8000/health
kubectl exec "deployment/$env:API_NAME" --namespace $env:MANAGED_NAMESPACE_NAME -- wget -qO- http://127.0.0.1:8000/materials
kubectl exec "deployment/$env:WEB_NAME" --namespace $env:MANAGED_NAMESPACE_NAME -- wget -qO- http://127.0.0.1:8501/ |
    Select-String -SimpleMatch 'Material inventory', 'Caldovir 50 mg tablets'
```

Check that health reports a connected database and that both phrases appear
in the web output. These checks complement the browser and port-forward checks
in steps 3 and 4.

If a rollout fails, inspect the pod events and API logs. Common causes include
registry pull permissions, a mismatched federation subject, identity propagation,
PostgreSQL firewall rules, and database grants:

```powershell
kubectl describe pods --namespace $env:MANAGED_NAMESPACE_NAME
kubectl logs "deployment/$env:API_NAME" --namespace $env:MANAGED_NAMESPACE_NAME --tail=100
```

Do not paste tokens or sensitive logs into a prompt or public issue. Do not bypass
readiness or switch to demo data to make a failed database check look successful.
If you change a ConfigMap value after pods are running and the image digest stays
the same, restart the affected deployments so their containers receive the new
environment values, then check their rollout again:

```powershell
kubectl rollout restart "deployment/$env:API_NAME" "deployment/$env:WEB_NAME" `
    --namespace $env:MANAGED_NAMESPACE_NAME
kubectl rollout status "deployment/$env:API_NAME" --namespace $env:MANAGED_NAMESPACE_NAME --timeout=10m
kubectl rollout status "deployment/$env:WEB_NAME" --namespace $env:MANAGED_NAMESPACE_NAME --timeout=10m
```

## 3. Connect from your workstation

Choose two different free local ports between 1 and 65535 in the main lab
terminal. Check that the displayed values are correct before continuing.

```powershell
$env:API_PORT = Read-Host 'Free local port for the API'
$env:WEB_PORT = Read-Host 'Different free local port for the web application'
"Kubeconfig: $env:KUBECONFIG"
"Namespace: $env:MANAGED_NAMESPACE_NAME"
"API service and local port: $env:API_NAME, $env:API_PORT"
"Web service and local port: $env:WEB_NAME, $env:WEB_PORT"
```

Open two additional PowerShell terminals. In each, run the following block and
enter the values displayed above: use the API service and port in one terminal,
and the web service and port in the other. Leave both commands running.

```powershell
$env:KUBECONFIG = Read-Host 'Workshop kubeconfig path'
$namespace = Read-Host 'Workshop namespace'
$service = Read-Host 'Service name'
$localPort = Read-Host 'Local port for this service'
kubectl port-forward "service/$service" ("{0}:80" -f $localPort) `
    --namespace $namespace --address 127.0.0.1
```

Wait for both terminals to report that forwarding is active. The forwards listen
only on your workstation. If a target pod is replaced, stop and restart its
forward. Stop both with Ctrl+C when finished.

## 4. Verify the API and web application

In the main lab terminal, query the API and display the health and inventory
responses:

```powershell
$apiBase = 'http://127.0.0.1:{0}' -f $env:API_PORT
$live = Invoke-RestMethod -Uri "$apiBase/live"
$health = Invoke-RestMethod -Uri "$apiBase/health"
$materials = Invoke-RestMethod -Uri "$apiBase/materials"
$live
$health
"Inventory lots: $($materials.Count)"
$materials | Select-Object name, lot_number, quantity, status | Format-Table
$materials | Select-Object id, name, category, lot_number, quantity, unit, status, location, expiry_date, image_url | Format-List
"Open the web application at http://127.0.0.1:$env:WEB_PORT"
```

Confirm `/live` reports `alive`, `/health` reports `healthy` and `connected`,
and `/materials` returns an array of six lots. Each lot should include the
fields shown above. Check that one is `Caldovir 50 mg tablets`, with quantity
`1240` and status `In stock`. Stop and investigate if a check fails.

Open the displayed web address. Confirm that the six sample materials appear,
search for a material, and filter by stock status. The sample contains synthetic
data only. The browser may request external fonts and sample images. If the page
reports that the API is unavailable, investigate rather than treating the web
page's HTTP response as an end-to-end success.

## Return to your module

Keep the main terminal open so the inventory response remains available for
comparison. Return to [Python]({{ site.baseurl }}{% link appmod-lab/3-deploy-to-azure/deploy-to-azure-3-2-python.md %}#4-record-the-comparison-baseline-optional)
or [Java]({{ site.baseurl }}{% link appmod-lab/3-deploy-to-azure/deploy-to-azure-3-3-java.md %}#3-compare-behavior-optional).
