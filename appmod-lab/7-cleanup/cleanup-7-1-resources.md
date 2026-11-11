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

> [!CAUTION]
> Deleting a resource group deletes **everything** in it. Only delete the new,
> dedicated group created for this workshop after reviewing its contents and
> confirming the subscription and name with its owner.

## 1. Stop access and identify the resources

Stop both `kubectl port-forward` commands with Ctrl+C. In the main lab terminal,
confirm your saved non-secret settings. If the original terminal was closed,
restore `LAB_SUBSCRIPTION`, `LAB_PREFIX`, `LAB_SUFFIX`, and `LAB_RG` from the
private notes made in module 03, and sign in to the correct Azure tenant. Also
restore `LAB_NODE_RG` if the cluster was created.

```powershell
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
if (-not $env:LAB_SUBSCRIPTION -or -not $env:LAB_PREFIX -or
    -not $env:LAB_SUFFIX -or -not $env:LAB_RG) {
    throw 'Restore the recorded lab subscription, prefix, suffix, and resource group first.'
}
$currentSubscription = (az account show --query id --output tsv).Trim()
if ($currentSubscription -ne $env:LAB_SUBSCRIPTION) {
    throw 'The active subscription is not the recorded workshop subscription.'
}
$expectedGroup = '{0}-rg-{1}' -f $env:LAB_PREFIX, $env:LAB_SUFFIX
if ($env:LAB_RG -cne $expectedGroup) {
    throw 'The resource group does not match the recorded lab naming pattern.'
}
az account show --query "{Name:name,Id:id,Tenant:tenantId}" --output table
$groupExists = (az group exists --subscription $env:LAB_SUBSCRIPTION --name $env:LAB_RG --output tsv).Trim()
if ($groupExists -eq 'true') {
    az group show --subscription $env:LAB_SUBSCRIPTION --name $env:LAB_RG `
        --query "{Name:name,Location:location}" --output table
    az resource list --subscription $env:LAB_SUBSCRIPTION --resource-group $env:LAB_RG --output table
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
should be retained, stop. Record the AKS node resource group from module 03 before
deleting the cluster.

## 2. Delete and verify

If the group exists, confirm the displayed subscription and group contents, then
enter the exact resource group name to start deletion:

```powershell
if ((az account show --query id --output tsv).Trim() -ne $env:LAB_SUBSCRIPTION) {
    throw 'The active subscription changed. Stop and recheck the lab settings.'
}
if ((Read-Host 'Type the exact workshop resource group name to delete it') -cne $env:LAB_RG) {
    throw 'Resource group deletion was not confirmed.'
}
az group delete --subscription $env:LAB_SUBSCRIPTION --name $env:LAB_RG --yes --no-wait
```

Deletion is asynchronous. Run the following check until it prints `false`:

```powershell
az group exists --subscription $env:LAB_SUBSCRIPTION --name $env:LAB_RG --output tsv
if ($env:LAB_NODE_RG) {
    az group exists --subscription $env:LAB_SUBSCRIPTION --name $env:LAB_NODE_RG --output tsv
}
else {
    'No node resource group was recorded. Verify in the Azure portal whether one remains.'
}
```

Also check the Azure portal for a failed or incomplete deletion and confirm that
the recorded AKS-managed node resource group and billable resources were removed.
Review any monitoring workspaces or supporting resources created outside the lab
group with their owner. They may be shared or retained after cluster deletion; do
not delete them without confirming ownership and dependencies. If deletion fails or
remains in progress when you leave, record the error and hand it to the named owner;
do not report cleanup as complete.

## 3. Remove temporary files and credentials

The temporary build directory and kubeconfig are local to the workstation. If you
reopened the terminal, restore `LAB_BUILD_ROOT` and `KUBECONFIG` from your notes.
Alternatively, after confirming the recorded suffix, reconstruct them for this
PowerShell session:

```powershell
$env:LAB_BUILD_ROOT = Join-Path ([IO.Path]::GetTempPath()) "caldova-build-$($env:LAB_SUFFIX)"
$env:KUBECONFIG = Join-Path ([IO.Path]::GetTempPath()) "caldova-$($env:LAB_SUFFIX).kubeconfig"
```

Review the paths before confirming deletion. The following checks prevent these
commands from deleting a different path:

```powershell
$expectedBuildRoot = Join-Path ([IO.Path]::GetTempPath()) "caldova-build-$($env:LAB_SUFFIX)"
$expectedKubeconfig = Join-Path ([IO.Path]::GetTempPath()) "caldova-$($env:LAB_SUFFIX).kubeconfig"
if (-not $env:LAB_BUILD_ROOT -or -not $env:KUBECONFIG -or
    [IO.Path]::GetFullPath($env:LAB_BUILD_ROOT) -ne [IO.Path]::GetFullPath($expectedBuildRoot) -or
    [IO.Path]::GetFullPath($env:KUBECONFIG) -ne [IO.Path]::GetFullPath($expectedKubeconfig)) {
    throw 'The temporary paths do not match this lab. Inspect them before deleting anything.'
}
"Temporary build directory: $env:LAB_BUILD_ROOT"
"Temporary kubeconfig: $env:KUBECONFIG"
if ((Read-Host 'Type delete local files to remove these paths') -cne 'delete local files') {
    throw 'Local cleanup was not confirmed.'
}
if (Test-Path -LiteralPath $env:LAB_BUILD_ROOT) {
    Remove-Item -LiteralPath $env:LAB_BUILD_ROOT -Recurse -Force
}
if (Test-Path -LiteralPath $env:KUBECONFIG) {
    Remove-Item -LiteralPath $env:KUBECONFIG -Force
}
Remove-Item Env:KUBECONFIG
```

The PostgreSQL token was removed from the setup terminal after database
initialization. Close that terminal when finished.

In the disposable `AKS_AppMod_Demos` fork, disable the modernization workflow or repository Actions,
remove the two demonstration Actions secrets, and revoke the short-lived tokens if
they are no longer needed. Follow your organization's retention policy for the
fork, branches, workflow logs, and artifacts. Do not delete the original repository.

## Checkpoint

The resource group and its managed resources are gone, or a named owner has accepted
the remaining deletion work. Port forwards are stopped, local lab files are removed,
and demonstration automation and credentials are disabled or revoked.

[Workshop home]({% link index.md %}) |
[Facilitator guide]({% link appmod-lab/facilitator-guide.md %})
