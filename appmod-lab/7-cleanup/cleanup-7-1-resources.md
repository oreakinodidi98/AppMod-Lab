---
title: Remove and verify workshop resources
description: Remove the dedicated Azure resource group, temporary files, and workshop credentials.
ms.topic: tutorial
parent: Module 07 - Clean up the workshop
nav_order: 1
---

## Goals

Stop the port forwards, delete the dedicated lab resources, verify deletion, and
remove temporary access. If the environment must be retained, agree on an owner,
cost limit, and deletion time instead of leaving it unattended.

Finish all modules before deleting the shared environment. For module 05,
stop both local Python services and remove `DATABASE_URL` from their terminal.
For module 06, stop PetClinic and run `docker compose down` from its checkout.
Remove datasource password variables and review any local database volumes or
dumps before deleting them. Do not stop or delete unrelated local databases.
Use the manual steps below rather than the reference cleanup script.

> [!CAUTION]
> Deleting a resource group deletes **everything** in it. Only delete the new,
> dedicated group created for this workshop after reviewing its contents and
> confirming the subscription and name with its owner.

## 1. Stop access and identify the resources

Stop both `kubectl port-forward` commands with Ctrl+C. If the environment setup
terminal is still open, use it. If not, open PowerShell in your workshop
repository and read the values saved by module 03. The block below reads only
the listed variables from `.envrc`; it does not execute the file.

```powershell
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$env:LAB_APP_REPO = (git rev-parse --show-toplevel).Trim()
$envrcPath = Join-Path $env:LAB_APP_REPO '.envrc'
$requiredSettings = @(
    'AZURE_SUBSCRIPTION_ID', 'NAME_PREFIX', 'NAME_SUFFIX', 'RG_NAME', 'AKS_NAME',
    'AKS_NODE_RESOURCE_GROUP', 'AKS_KUBECONFIG_PATH', 'BUILD_ROOT'
)
$savedSettings = @{}
Get-Content -LiteralPath $envrcPath | ForEach-Object {
    if ($_ -match '^export ([A-Z][A-Z0-9_]*)=(.*)$' -and $matches[1] -in $requiredSettings) {
        $savedSettings[$matches[1]] = $matches[2]
    }
}
foreach ($setting in $requiredSettings) {
    if (-not $savedSettings.ContainsKey($setting) -or
        [string]::IsNullOrWhiteSpace($savedSettings[$setting])) {
        throw "The .envrc file is missing $setting. Restore it from the module 03 terminal."
    }
    Set-Item -Path "Env:$setting" -Value $savedSettings[$setting]
}
$env:KUBECONFIG = $env:AKS_KUBECONFIG_PATH
$currentSubscription = (az account show --query id --output tsv).Trim()
if ($currentSubscription -ne $env:AZURE_SUBSCRIPTION_ID) {
    throw 'The active subscription is not the recorded workshop subscription.'
}
az account show --query "{Name:name,Id:id,Tenant:tenantId}" --output table
$groupExists = (az group exists --subscription $env:AZURE_SUBSCRIPTION_ID `
    --name $env:RG_NAME --output tsv).Trim()
if ($groupExists -eq 'true') {
    az group show --subscription $env:AZURE_SUBSCRIPTION_ID --name $env:RG_NAME `
        --query "{Name:name,Location:location}" --output table
    az resource list --subscription $env:AZURE_SUBSCRIPTION_ID `
        --resource-group $env:RG_NAME --output table
}
elseif ($groupExists -eq 'false') {
    'The recorded workshop resource group is already absent.'
}
else {
    throw 'The resource group existence could not be verified.'
}
```

Review the resource list with the owner. If the group was never created or is
already absent, skip the deletion command. If the group contains anything that
should be retained, stop. Module 03 saved the AKS-managed node resource group
name in `.envrc` for the deletion check.

## 2. Delete and verify

If the group exists, confirm the displayed subscription and group contents, then
enter the exact resource group name to start deletion:

```powershell
if ((az account show --query id --output tsv).Trim() -ne $env:AZURE_SUBSCRIPTION_ID) {
    throw 'The active subscription changed. Stop and recheck the lab settings.'
}
if ((Read-Host 'Type the exact workshop resource group name to delete it') -cne $env:RG_NAME) {
    throw 'Resource group deletion was not confirmed.'
}
az group delete --subscription $env:AZURE_SUBSCRIPTION_ID --name $env:RG_NAME --yes --no-wait
```

Deletion is asynchronous. Run the following check until it prints `false`:

```powershell
az group exists --subscription $env:AZURE_SUBSCRIPTION_ID --name $env:RG_NAME --output tsv
az group exists --subscription $env:AZURE_SUBSCRIPTION_ID `
    --name $env:AKS_NODE_RESOURCE_GROUP --output tsv
```

Also check the Azure portal for a failed or incomplete deletion and confirm that
the recorded AKS-managed node resource group and billable resources were removed.
Review any monitoring workspaces or supporting resources created outside the lab
group with their owner. They may be shared or retained after cluster deletion; do
not delete them without confirming ownership and dependencies. If deletion fails or
remains in progress when you leave, record the error and hand it to the named owner;
do not report cleanup as complete.

## 3. Remove temporary files and credentials

The temporary build directory and kubeconfig are local to the workstation.
Review the saved paths before confirming deletion:

```powershell
"Temporary build directory: $env:BUILD_ROOT"
"Temporary kubeconfig: $env:AKS_KUBECONFIG_PATH"
"Workshop settings file: $env:LAB_APP_REPO\.envrc"
$expectedBuildRoot = Join-Path $env:TEMP "caldova-build-$env:NAME_SUFFIX"
$expectedKubeconfig = Join-Path (Join-Path $HOME 'appmod-Student\deploy-to-azure') `
    "$env:AKS_NAME.kubeconfig"
if ([IO.Path]::GetFullPath($env:BUILD_ROOT) -ne [IO.Path]::GetFullPath($expectedBuildRoot) -or
    [IO.Path]::GetFullPath($env:AKS_KUBECONFIG_PATH) -ne [IO.Path]::GetFullPath($expectedKubeconfig)) {
    throw 'The temporary paths do not match this lab. Inspect them before deleting anything.'
}
if ((Read-Host 'Type delete local files to remove the lab build files, kubeconfig, and .envrc') `
    -cne 'delete local files') {
    throw 'Local cleanup was not confirmed.'
}
if (Test-Path -LiteralPath $env:BUILD_ROOT) {
    Remove-Item -LiteralPath $env:BUILD_ROOT -Recurse -Force
}
if (Test-Path -LiteralPath $env:AKS_KUBECONFIG_PATH) {
    Remove-Item -LiteralPath $env:AKS_KUBECONFIG_PATH -Force
}
if (Test-Path -LiteralPath (Join-Path $env:LAB_APP_REPO '.envrc')) {
    Remove-Item -LiteralPath (Join-Path $env:LAB_APP_REPO '.envrc') -Force
}
Remove-Item Env:KUBECONFIG
```

The PostgreSQL token was removed from the setup terminal after database
initialization. Close that terminal when finished.

In your disposable workshop repository, disable the modernization workflow or repository Actions,
remove the two demonstration Actions secrets, and revoke the short-lived tokens if
they are no longer needed. Follow your organization's retention policy for the
repository, branches, workflow logs, and artifacts. Do not delete the original lab repository.

## Checkpoint

The resource group and its managed resources are gone, or a named owner has accepted
the remaining deletion work. Port forwards are stopped, local lab files are removed,
and demonstration automation and credentials are disabled or revoked.

[Workshop home]({{ site.baseurl }}{% link index.md %}) |
[Facilitator guide]({{ site.baseurl }}{% link appmod-lab/facilitator-guide.md %})
