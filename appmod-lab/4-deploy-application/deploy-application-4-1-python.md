---
title: Deploy and verify Python
description: Build the Python Caldova API and web application and verify them on AKS.
ms.topic: tutorial
parent: Module 04 - Deploy the application to Azure
nav_order: 1
---

## Goals

Deploy the existing Python implementation to the environment from
[module 03]({{ site.baseurl }}{% link appmod-lab/3-azure-environment/index.md %}). Verify that the application uses the
seeded PostgreSQL database through Microsoft Entra Workload ID.

## 1. Understand the application

Download the Python app into your workshop repository:

```powershell
Set-Location -LiteralPath $env:LAB_APP_REPO
& $env:LAB_SETUP -Module python
git status --short
```

Review `Python_app/CaldovaClinicalApi/main.py`, the web application in
`Python_app/CaldovaClinicalWeb/caldova_home.py`, and the database seed downloaded
in module 03 at `Python_app/CaldovaClinicalApi/db/init.sql`.

Trace a request from the browser to the web application, the `/materials` API, and
PostgreSQL. Find the separate liveness and database-readiness endpoints. Identify
how the API gets a database token without storing a database password.

You can ask Copilot to explain this flow using the files above. Review its answer
against the code, and do not include tokens, customer data, or connection secrets
in the prompt.

## 2. Prepare the Python build contexts

Commit the reviewed app files to your workshop repository. The build uses only
the committed files listed below, not uncommitted changes:

```powershell
git add -- Python_app/CaldovaClinicalApi/Dockerfile Python_app/CaldovaClinicalApi/main.py `
    Python_app/CaldovaClinicalApi/requirements.txt Python_app/CaldovaClinicalWeb
git commit -m "Add Python Caldova application"
```

Create the temporary build contexts in the same PowerShell terminal used for module 03:

```powershell
Set-Location -LiteralPath $env:LAB_APP_REPO
if (Test-Path -LiteralPath (Join-Path $env:LAB_BUILD_ROOT 'Python_app')) {
    throw 'Python build contexts already exist. Review them before recreating them.'
}
$archive = Join-Path $env:LAB_BUILD_ROOT 'python-source.tar'
$sourcePaths = @(
    'Python_app/CaldovaClinicalApi/Dockerfile', 'Python_app/CaldovaClinicalApi/main.py',
    'Python_app/CaldovaClinicalApi/requirements.txt', 'Python_app/CaldovaClinicalWeb/Dockerfile',
    'Python_app/CaldovaClinicalWeb/app.py', 'Python_app/CaldovaClinicalWeb/caldova_home.py',
    'Python_app/CaldovaClinicalWeb/requirements.txt'
)
git -C $env:LAB_APP_REPO archive --format=tar --output $archive HEAD -- $sourcePaths
tar -xf $archive -C $env:LAB_BUILD_ROOT
Remove-Item -LiteralPath $archive
git --no-pager -C $env:LAB_APP_REPO log -1 --format='%h %s'
$env:LAB_API_CONTEXT = Join-Path $env:LAB_BUILD_ROOT 'Python_app\CaldovaClinicalApi'
$env:LAB_WEB_CONTEXT = Join-Path $env:LAB_BUILD_ROOT 'Python_app\CaldovaClinicalWeb'
$env:LAB_API_REPOSITORY = "$($env:LAB_PREFIX)/python-api"
$env:LAB_WEB_REPOSITORY = "$($env:LAB_PREFIX)/python-web"
```

Review the contents of both contexts before uploading them. The file list is not a
substitute for secret scanning.

Follow the [shared build and deployment exercise]({{ site.baseurl }}{% link appmod-lab/4-deploy-application/deploy-caldova.md %}), then return
here. It builds both images in your registry, deploys them to your namespace, and
checks the actual database-backed inventory. The Python web application caches
inventory responses for up to 30 seconds.

## 3. Record the comparison baseline

If you also want to try Java, save the returned synthetic inventory in this
PowerShell session after the shared exercise succeeds. Otherwise, continue to
module 05:

```powershell
$pythonInventorySnapshot = @(
    $materials | Sort-Object lot_number |
        Select-Object id, name, category, lot_number, quantity, unit, status, location, expiry_date, image_url
)
```

The snapshot is only in memory. It is not a substitute for inspecting the application
in the browser or checking the API response.

## Checkpoint

Both Python pods are ready, `/health` reports a connected database, `/materials`
returns all six seeded lots, and the web page displays the inventory. You can explain
which identity connects to PostgreSQL and why readiness is separate from liveness.

[Next: operate and improve]({{ site.baseurl }}{% link appmod-lab/5-operate-and-improve/index.md %}) |
[Compare with Java]({{ site.baseurl }}{% link appmod-lab/4-deploy-application/deploy-application-4-2-java.md %}) |
[Workshop home]({{ site.baseurl }}{% link index.md %})
