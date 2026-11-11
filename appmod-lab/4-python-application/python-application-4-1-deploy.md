---
title: Deploy and verify Python
description: Build the Python Caldova API and web application and verify them on AKS.
ms.topic: tutorial
parent: Module 04 - Deploy the Python application
nav_order: 1
---

## Goals

Deploy the existing Python implementation to the environment from
[module 03]({% link appmod-lab/3-azure-environment/index.md %}). Verify that the application uses the
seeded PostgreSQL database through Microsoft Entra Workload ID.

## 1. Understand the application

Review the [Python API](https://github.com/oreakinodidi98/AKS_AppMod_Demos/blob/main/Python_app/CaldovaClinicalApi/main.py),
the [web application](https://github.com/oreakinodidi98/AKS_AppMod_Demos/blob/main/Python_app/CaldovaClinicalWeb/caldova_home.py),
and the [database seed](https://github.com/oreakinodidi98/AKS_AppMod_Demos/blob/main/Python_app/CaldovaClinicalApi/db/init.sql)
in `AKS_AppMod_Demos`. Locally, these files are under `LAB_APP_REPO`, not `LAB_REPO`.

Trace a request from the browser to the web application, the `/materials` API, and
PostgreSQL. Find the separate liveness and database-readiness endpoints. Identify
how the API gets a database token without storing a database password.

You can ask Copilot to explain this flow using the files above. Review its answer
against the code, and do not include tokens, customer data, or connection secrets
in the prompt.

## 2. Select the Python build contexts

In the same PowerShell terminal used for module 03, select the temporary contexts
that were created from the reviewed commit:

```powershell
Set-Location -LiteralPath $env:LAB_APP_REPO
$env:LAB_API_CONTEXT = Join-Path $env:LAB_BUILD_ROOT 'Python_app\CaldovaClinicalApi'
$env:LAB_WEB_CONTEXT = Join-Path $env:LAB_BUILD_ROOT 'Python_app\CaldovaClinicalWeb'
$env:LAB_API_REPOSITORY = "$($env:LAB_PREFIX)/python-api"
$env:LAB_WEB_REPOSITORY = "$($env:LAB_PREFIX)/python-web"
```

Follow the [shared build and deployment exercise]({% link appmod-lab/4-python-application/deploy-caldova.md %}), then return
here. It builds both images in your registry, deploys them to your namespace, and
checks the actual database-backed inventory. The Python web application caches
inventory responses for up to 30 seconds.

## 3. Record the comparison baseline

After the shared exercise succeeds, save the returned synthetic inventory in this
PowerShell session for comparison with Java:

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

[Next: Caldova Java]({% link appmod-lab/5-java-application/index.md %}) |
[Workshop home]({% link index.md %})
