---
title: Module 00 - Prepare for the workshop
description: Check the tools, permissions, network access, and safety boundaries for the workshop.
ms.topic: tutorial
parent: Prerequisites
nav_order: 1
---

## Goals

Create a repository for your work and check the access needed to provision a temporary Azure environment. Complete the access and quota checks with the facilitator before the workshop day.

## GitHub and local tools

You need:

* A GitHub account with GitHub Copilot enabled and permission to create a repository. The automated exercise also needs GitHub Actions and the token permissions described in [module 02]({{ site.baseurl }}{% link appmod-lab/2-automated-modernization/index.md %}).

* [Visual Studio Code](https://code.visualstudio.com/download) with [GitHub Copilot](https://code.visualstudio.com/docs/setup/copilot) and the [GitHub Copilot modernization extension](https://marketplace.visualstudio.com/items?itemName=vscjava.migrate-java-to-azure).

* A Windows workstation with:
    * [Git for Windows](https://git-scm.com/install/windows).
    * [PowerShell 7.4 or later](https://learn.microsoft.com/powershell/scripting/install/install-powershell-on-windows), not Windows PowerShell 5.1.
    * [Maven 3](https://maven.apache.org/download.cgi). Choose a Maven 3 binary download, not Maven 4.

    * A [Java 8 JDK](https://adoptium.net/temurin/releases/?version=8&os=windows&package=jdk) and a [JDK for your chosen upgrade target](https://adoptium.net/temurin/releases/?os=windows&package=jdk). Select the agreed version and a **JDK**, not a JRE. Install [JDK 17](https://adoptium.net/temurin/releases/?version=17&os=windows&package=jdk) as well if you choose the Java path in module 04.

* These command-line tools, available on your command path:
    * [Azure CLI 2.86.0 or later](https://learn.microsoft.com/cli/azure/install-azure-cli-windows).
    * [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/) and [kubelogin](https://azure.github.io/kubelogin/install.html#windows).

    * [PostgreSQL command-line tools, including psql](https://www.postgresql.org/download/windows/). Select **Command Line Tools** in the Windows installer and add its `bin` folder to your `PATH`.

    * [tar](https://learn.microsoft.com/windows/tar/), which is included with Windows; no separate download is needed.

* Access to the public dependencies and base images used by the applications, subject to your organization's network and software policies.

The examples use PowerShell and Windows paths on your own workstation.
You will need Docker and a local PostgreSQL server for the later modules below.

Check these tools before the later modules:

* [Module 06]({{ site.baseurl }}{% link appmod-lab/6-caldova-source-modernization/index.md %}) needs [Python 3.11 or later](https://www.python.org/downloads/windows/) and a local [PostgreSQL 15 or later server](https://www.postgresql.org/download/windows/).

* [Module 07]({{ site.baseurl }}{% link appmod-lab/7-petclinic-aks-automatic/index.md %}) needs [Docker Desktop for Windows](https://docs.docker.com/desktop/setup/install/windows-install/) with Linux containers, [Docker Compose](https://docs.docker.com/compose/install/) (included with Docker Desktop), the [Java Extension Pack](https://marketplace.visualstudio.com/items?itemName=vscjava.vscode-java-pack), and a [JDK compatible with the selected PetClinic version](https://adoptium.net/temurin/releases/?os=windows&package=jdk). Check the modernization extension's own JDK requirements too.

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
* You can reach the Kubernetes API and PostgreSQL from your workstation and access the registry and package sources required by ACR builds.
* You understand which monitoring workspaces AKS may create or reuse, who owns them, and whether their costs and resource groups are approved.
* Browser requests for the sample's external fonts and inventory images are allowed by your organization's policy.

If these conditions are not met, stop and agree an approved environment with the
facilitator. Do not open PostgreSQL to all Azure addresses or bypass security
policies. AKS, database, registry, networking, and build usage are billable.

## Create your workshop repository

1. On GitHub, create a new repository in an account or organization where you can run the workshop. Add a README when creating it so it has a default branch.

2. Copy your new repository's URL from **Code > HTTPS**. In Visual Studio Code, open the Command Palette with **Ctrl+Shift+P**, select **Git: Clone**, and paste the URL. Choose where to save it, then open the cloned repository when prompted. If you have already cloned your repository, open that folder instead.

3. Open a new terminal in VS Code with **Terminal > New Terminal** and select **PowerShell 7**. The terminal needs to be inside your cloned repository, not just on the GitHub website. If needed, use `Set-Location` to move into its folder:

   ```powershell
   Set-Location -LiteralPath 'C:\path\to\your\workshop-repository'
   ```

   Replace the example path with the folder on your computer. For example, if
   your prompt already shows `PS C:\Users\oreakinodidi\AppMod-Student>`, you
   are already in that folder and can skip this command.

Keep your repository's default branch for the automated exercise. Module 01 uses
a separate branch for the interactive upgrade.

Now run the following in that terminal. You do not need to enter a path when
prompted. Git finds the repository's top-level folder and the command saves it
as `LAB_APP_REPO` for the later exercises.

```powershell
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$env:LAB_APP_REPO = $null
$repoRoot = git rev-parse --show-toplevel
Set-Location -LiteralPath $repoRoot
$env:LAB_APP_REPO = (Get-Location).Path
git remote -v
git status --short
```

Check that the `origin` push URL shown points to **your** new GitHub repository,
and that `git status` shows no unrelated changes. If Git says this is not a
repository, open the cloned folder in VS Code and try again. If the remote points
somewhere else or there are unrelated changes, stop and use the correct clone.
Keep this terminal open for the workshop; the lab settings are session variables.

## Get the setup command

Download the setup script once, check its hash, and read it before running it.
It downloads only the files for the module you choose; it won't overwrite existing
files. The script and starter files are checked against the workshop's reviewed
versions. If a check fails, stop and ask the facilitator for the matching instructions.

```powershell
$env:LAB_SETUP = Join-Path ([IO.Path]::GetTempPath()) 'appmod-lab-get-files.ps1'
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/scripts/get-lab-files.ps1' -OutFile $env:LAB_SETUP
$expected = '250b6920419840bc8536d5753799b16a0c1963cb3bab4db2dbcafb1f7e076009'
if ((Get-FileHash -LiteralPath $env:LAB_SETUP -Algorithm SHA256).Hash -ne $expected) {
    throw 'The setup script does not match these workshop instructions. Do not run it.'
}
Get-Content -LiteralPath $env:LAB_SETUP
```

In each module, run its `& $env:LAB_SETUP -Module ...` command from the root of
your repository. Review and commit the downloaded files before continuing. The
setup command never commits or pushes for you. If a download is interrupted, read
the error and check `git status` before removing any partial files and retrying.
If you restart PowerShell, open your cloned repository in the new terminal, rerun
the commands above to set `LAB_APP_REPO`, then repeat the script download and hash
check. Never record tokens or passwords in your notes.

## Checkpoint

You can identify your repository, selected subscription, resource owner, approved region,
network design, and cleanup owner. You have the tools and permissions for the modules
you will run.

[Next: naming]({{ site.baseurl }}{% link appmod-lab/0-prerequisites/prerequisite-0-2-naming.md %}) |
[Workshop home]({{ site.baseurl }}{% link index.md %})
