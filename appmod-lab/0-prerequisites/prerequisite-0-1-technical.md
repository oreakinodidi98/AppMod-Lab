---
title: Module 00 - Prepare for the workshop
description: Check the tools, permissions, network access, and safety boundaries for the workshop.
ms.topic: tutorial
parent: Prerequisites
nav_order: 1
---

## Goals

Prepare a disposable GitHub fork and the access needed to provision a temporary Azure environment. Complete the access and quota checks with the facilitator before the workshop day.

## GitHub and local tools

You need:

* A GitHub account with GitHub Copilot enabled and permission to create a fork. The automated exercise also needs GitHub Actions and the token permissions described in [module 02](../2-automated-modernization/).
* Visual Studio Code with GitHub Copilot and the [GitHub Copilot modernization extension](https://marketplace.visualstudio.com/items?itemName=vscjava.migrate-java-to-azure).
* A Windows workstation with Git, PowerShell 7.4 or later, Maven 3, a Java 8 JDK, and the JDK for your chosen upgrade target. Install JDK 17 as well for the Caldova Java exercise.
* Azure CLI 2.86.0 or later, `kubectl`, `kubelogin`, `psql`, and `tar` available on your command path.
* Access to the public dependencies and base images used by the applications, subject to your organization's network and software policies.

The examples use PowerShell and Windows paths on your own workstation. A local
Docker installation is not required: ACR builds the container images. PostgreSQL
client tools are required, but a local PostgreSQL server is not.

Check the commands in a new PowerShell session:

```powershell
git --version
pwsh --version
mvn --version
az --version
kubectl version --client
kubelogin --version
psql --version
tar --version
```

Install or configure any missing tool using your organization's approved process.
The Java version displayed by Maven must match the JDK needed for each exercise; you
will select it in the module rather than rely on a workstation-specific path.

## Azure access and costs

Use a non-production Azure subscription in which you are authorized to create and
delete a new resource group and the following resources:

* An AKS Automatic cluster and its managed networking
* An ACR registry with ACR Tasks enabled
* An Azure Database for PostgreSQL flexible server
* A user-assigned managed identity and a federated identity credential

You also need permission to register or use the required resource providers, create
the AKS-to-ACR pull role assignment, read your signed-in Microsoft Entra user, and
create a database administrator and database. You need read access to the
AKS-managed node resource group and outbound IP resources, as well as access to the
Kubernetes API. An administrator may need to grant these permissions or perform
approved setup in advance. When the Azure CLI creates an AKS Automatic cluster, it
assigns the signed-in user the **Azure Kubernetes Service RBAC Cluster Admin** role.
Agree to that cluster-scoped access and the required role-assignment permissions
before the workshop.

Check with the customer that:

* The selected region supports AKS Automatic and the chosen PostgreSQL tier and SKU.
* The subscription has sufficient quota, resource-provider registration, and budget.
* A public AKS API and a PostgreSQL public endpoint restricted to the workshop's public IPv4 addresses are allowed for this temporary lab.
* Any managed ingress or Gateway resources provisioned by AKS Automatic are permitted and included in the cost and cleanup review. This lab does not route the application through them.
* You know your workstation or corporate network's public outbound IPv4 address. A private workstation address is not sufficient.
* You can reach the Kubernetes API and PostgreSQL from your workstation and access the registry and package sources required by ACR builds.
* You understand which monitoring workspaces AKS may create or reuse, who owns them, and whether their costs and resource groups are approved.
* Browser requests for the sample's external fonts and inventory images are allowed by your organization's policy.

If these conditions are not met, stop and agree an approved environment with the
facilitator. Do not open PostgreSQL to all Azure addresses or bypass security
policies. AKS, database, registry, networking, and build usage are billable.

## Create your working copy

1. Fork the repository into an account or organization where you have permission to run the workshop. Use a disposable fork, not a production repository.
2. Clone your fork with Git or GitHub Desktop. Open the repository root in Visual Studio Code.
3. Keep the fork's default branch as the baseline for the automated exercise. Do interactive upgrade work on a separate branch.
4. Before enabling workflows, review the safety steps in [module 02](../2-automated-modernization/). Several existing deployment workflows target a different demonstration environment.

In PowerShell, set the path to your clone. Keep this terminal open for the workshop;
the lab settings are session variables and are not written to the repository.

```powershell
$env:LAB_REPO = Read-Host 'Full path to your cloned repository root'
Set-Location -LiteralPath $env:LAB_REPO
if (-not (Test-Path (Join-Path $env:LAB_REPO 'src\pom.xml'))) {
    throw 'The selected directory is not the workshop repository root.'
}
$env:LAB_REPO = (Get-Location).Path
git remote -v
git status --short
```

Confirm that the push remote points to your disposable fork. Do not proceed with
unrelated working-tree changes; preserve them and use a separate clone if necessary.
If you open another terminal or restart PowerShell, re-enter the required settings
from your private notes. Never record tokens or passwords in those notes.

## Checkpoint

You can identify your fork, selected subscription, resource owner, approved region,
network design, and cleanup owner. You have the tools and permissions for the modules
you will run.

[Next: interactive modernization](../1-interactive-modernization/) |
[Workshop home](../../index.md)
