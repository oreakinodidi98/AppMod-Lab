---
title: Build and deploy Caldova
description: Build participant-specific images, deploy them on AKS, and verify database-backed behavior.
ms.topic: tutorial
parent: Module 04 - Deploy the application to Azure
nav_order: 3
---

## Before you start

Complete [module 03]({{ site.baseurl }}{% link appmod-lab/3-azure-environment/azure-environment-3-1-setup.md %}) and select the Python or Java
contexts in the [Python path]({{ site.baseurl }}{% link appmod-lab/4-deploy-application/deploy-application-4-1-python.md %}) or
[Java path]({{ site.baseurl }}{% link appmod-lab/4-deploy-application/deploy-application-4-2-java.md %})
of module 04. Use the same PowerShell terminal and keep
your lab settings available. The commands operate only on your dedicated resource
group, registry, cluster, and namespace.

If you are switching implementations, stop the old port forwards first. The
deployment replaces their target pods, so you must start new forwards afterward.

## 1. Build and identify the images

Confirm the current Azure subscription and the reviewed build contexts before
uploading them. A new tag identifies this build; the deployment uses the resulting
immutable image digests rather than relying on a mutable tag.

```powershell
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
if ((az account show --query id --output tsv).Trim() -ne $env:LAB_SUBSCRIPTION) {
    throw 'The active Azure subscription does not match the workshop subscription.'
}
foreach ($context in @($env:LAB_API_CONTEXT, $env:LAB_WEB_CONTEXT)) {
    if (-not $context -or -not (Test-Path -LiteralPath (Join-Path $context 'Dockerfile'))) {
        throw 'A selected build context or its Dockerfile is missing. Return to the application module.'
    }
}

$tag = "lab-$([guid]::NewGuid().ToString('N').Substring(0, 12))"
$apiTag = '{0}:{1}' -f $env:LAB_API_REPOSITORY, $tag
$webTag = '{0}:{1}' -f $env:LAB_WEB_REPOSITORY, $tag
az acr build --resource-group $env:LAB_RG --registry $env:LAB_ACR `
    --file Dockerfile --image $apiTag $env:LAB_API_CONTEXT
az acr build --resource-group $env:LAB_RG --registry $env:LAB_ACR `
    --file Dockerfile --image $webTag $env:LAB_WEB_CONTEXT

$apiDigest = (az acr manifest show-metadata --registry $env:LAB_ACR `
    --name $apiTag --query digest --output tsv).Trim()
$webDigest = (az acr manifest show-metadata --registry $env:LAB_ACR `
    --name $webTag --query digest --output tsv).Trim()
if ($apiDigest -cnotmatch '^sha256:[a-f0-9]{64}$' -or
    $webDigest -cnotmatch '^sha256:[a-f0-9]{64}$') {
    throw 'A built image digest could not be verified.'
}
$env:LAB_API_IMAGE = '{0}/{1}@{2}' -f $env:LAB_REGISTRY, $env:LAB_API_REPOSITORY, $apiDigest
$env:LAB_WEB_IMAGE = '{0}/{1}@{2}' -f $env:LAB_REGISTRY, $env:LAB_WEB_REPOSITORY, $webDigest
"API image: $env:LAB_API_IMAGE"
"Web image: $env:LAB_WEB_IMAGE"
```

ACR Tasks must be enabled and able to reach the base images and package sources.
If a build fails, inspect the run's error and any image it created before retrying.
The `az acr manifest` command is in preview in Azure CLI.

## 2. Configure and deploy

The ConfigMap contains non-secret connection settings. The API pod receives its
managed identity configuration through the service account and workload identity
webhook; it does not receive a database password. Module 03 downloaded the template
into your workshop repository (`LAB_APP_REPO`).

```powershell
kubectl create configmap $env:LAB_CONFIG_NAME --namespace $env:LAB_NAMESPACE `
    --from-literal=DATA_MODE=database `
    --from-literal=DATABASE_AUTH_MODE=entra `
    "--from-literal=DATABASE_HOST=$env:LAB_PG_HOST" `
    --from-literal=DATABASE_PORT=5432 `
    "--from-literal=DATABASE_NAME=$env:LAB_PG_DATABASE" `
    "--from-literal=DATABASE_USER=$env:LAB_IDENTITY" `
    "--from-literal=CALDOVA_API_URL=http://$($env:LAB_API_NAME)" `
    --dry-run=client --output yaml |
    kubectl apply --namespace $env:LAB_NAMESPACE --filename -

$templatePath = Join-Path $env:LAB_APP_REPO 'assets\k8s\caldova.yaml'
$manifest = Get-Content -LiteralPath $templatePath -Raw
$values = @{
    '__API_NAME__' = $env:LAB_API_NAME
    '__WEB_NAME__' = $env:LAB_WEB_NAME
    '__SERVICE_ACCOUNT__' = $env:LAB_SERVICE_ACCOUNT
    '__CONFIG_NAME__' = $env:LAB_CONFIG_NAME
    '__API_IMAGE__' = $env:LAB_API_IMAGE
    '__WEB_IMAGE__' = $env:LAB_WEB_IMAGE
}
foreach ($entry in $values.GetEnumerator()) {
    if ([string]::IsNullOrWhiteSpace($entry.Value)) {
        throw "Missing a value for $($entry.Key)."
    }
    $manifest = $manifest.Replace($entry.Key, $entry.Value)
}
if ($manifest -match '__[A-Z_]+__') { throw 'The manifest contains an unresolved placeholder.' }
$manifest | kubectl apply --namespace $env:LAB_NAMESPACE --filename -

kubectl rollout status "deployment/$($env:LAB_API_NAME)" --namespace $env:LAB_NAMESPACE --timeout=10m
kubectl rollout status "deployment/$($env:LAB_WEB_NAME)" --namespace $env:LAB_NAMESPACE --timeout=10m
kubectl get deployments,pods,services --namespace $env:LAB_NAMESPACE
```

The API uses `/live` for startup and liveness and `/health` for database readiness.
The web probe checks its own HTTP endpoint; it does not prove that the API or
database is healthy. Image and application ports in the template are the fixed
contracts of these sample Dockerfiles, not Azure environment identifiers.

If a rollout fails, inspect the pod events and API logs. Common causes include
registry pull permissions, a mismatched federation subject, identity propagation,
PostgreSQL firewall rules, and database grants:

```powershell
kubectl describe pods --namespace $env:LAB_NAMESPACE
kubectl logs "deployment/$($env:LAB_API_NAME)" --namespace $env:LAB_NAMESPACE --tail=100
```

Do not paste tokens or sensitive logs into a prompt or public issue. Do not bypass
readiness or switch to demo data to make a failed database check look successful.
If you change a ConfigMap value after pods are running and the image digest stays
the same, restart the affected deployments so their containers receive the new
environment values, then check their rollout again:

```powershell
kubectl rollout restart "deployment/$($env:LAB_API_NAME)" "deployment/$($env:LAB_WEB_NAME)" `
    --namespace $env:LAB_NAMESPACE
kubectl rollout status "deployment/$($env:LAB_API_NAME)" --namespace $env:LAB_NAMESPACE --timeout=10m
kubectl rollout status "deployment/$($env:LAB_WEB_NAME)" --namespace $env:LAB_NAMESPACE --timeout=10m
```

## 3. Connect from your workstation

Choose two different free local ports in the main lab terminal:

```powershell
$env:LAB_API_PORT = Read-Host 'Free local port for the API'
$env:LAB_WEB_PORT = Read-Host 'Different free local port for the web application'
$apiPort = 0
$webPort = 0
if (-not [int]::TryParse($env:LAB_API_PORT, [ref]$apiPort) -or
    -not [int]::TryParse($env:LAB_WEB_PORT, [ref]$webPort) -or
    $apiPort -lt 1 -or $apiPort -gt 65535 -or
    $webPort -lt 1 -or $webPort -gt 65535 -or $apiPort -eq $webPort) {
    throw 'Choose two different port numbers between 1 and 65535.'
}
"Kubeconfig: $env:KUBECONFIG"
"Namespace: $env:LAB_NAMESPACE"
"API service and local port: $env:LAB_API_NAME, $env:LAB_API_PORT"
"Web service and local port: $env:LAB_WEB_NAME, $env:LAB_WEB_PORT"
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

In the main lab terminal, query the API and check the response shape and seed data:

```powershell
$apiBase = 'http://127.0.0.1:{0}' -f $env:LAB_API_PORT
$live = Invoke-RestMethod -Uri "$apiBase/live"
$health = Invoke-RestMethod -Uri "$apiBase/health"
$materials = Invoke-RestMethod -Uri "$apiBase/materials"
if ($live.status -ne 'alive' -or $health.status -ne 'healthy' -or $health.database -ne 'connected') {
    throw 'The API did not report a live process and connected database.'
}
if ($materials -isnot [array] -or $materials.Count -ne 6) {
    throw 'Expected an array containing the six seeded inventory lots.'
}
$fields = @('id', 'name', 'category', 'lot_number', 'quantity', 'unit', 'status', 'location', 'expiry_date', 'image_url')
foreach ($material in $materials) {
    $missing = @($fields | Where-Object { $_ -notin $material.PSObject.Properties.Name })
    if ($missing.Count -gt 0) { throw "The inventory response is missing fields: $($missing -join ', ')" }
}
$sample = @($materials | Where-Object { $_.name -eq 'Caldovir 50 mg tablets' })
if ($sample.Count -ne 1 -or $sample[0].quantity -ne 1240 -or $sample[0].status -ne 'In stock') {
    throw 'The expected seeded Caldovir inventory was not returned.'
}
$materials | Select-Object name, lot_number, quantity, status | Format-Table
"Open the web application at http://127.0.0.1:$env:LAB_WEB_PORT"
```

Open the displayed web address. Confirm that the six sample materials appear,
search for a material, and filter by stock status. The sample contains synthetic
data only. The browser may request external fonts and sample images. If the page
reports that the API is unavailable, investigate rather than treating the web
page's HTTP response as an end-to-end success.

## Return to your module

Keep the main terminal open so the inventory response remains available for
comparison. Return to [Python]({{ site.baseurl }}{% link appmod-lab/4-deploy-application/deploy-application-4-1-python.md %}#3-record-the-comparison-baseline)
or [Java]({{ site.baseurl }}{% link appmod-lab/4-deploy-application/deploy-application-4-2-java.md %}#3-compare-behavior).
