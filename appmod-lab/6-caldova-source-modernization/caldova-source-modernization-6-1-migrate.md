---
title: Run, assess, and modernize Caldova
description: Run Caldova locally, then use Copilot to prepare and test its AKS migration.
ms.topic: tutorial
parent: Module 06 - Modernize Caldova
nav_order: 1
---

## Goals

Run the Python Caldova app locally, then use Copilot to prepare it for AKS.
Unlike module 04, this exercise starts without Dockerfiles,
Kubernetes manifests, or passwordless database support. You generate and validate
those changes rather than starting with the already-modernized implementation.

Allow 90-120 minutes, plus time to create the Azure environment. Complete
[module 00]({% link appmod-lab/0-prerequisites/index.md %}) first. Before deploying, complete
[module 03]({% link appmod-lab/3-azure-environment/index.md %}), or ask your facilitator for a dedicated,
approved environment with equivalent registry, database, and identity access.

The starter app is stored in this lab's `assets/Scenario1App` folder.
Download it into your own repository using the command below. Keep all changes
inside `Scenario1App`; do not overwrite `Python_app`, which module 04 uses.

> [!IMPORTANT]
> Do not run `AutomaticSetup.ps1`, `ClassicSetup.ps1`, or `cleanup.ps1` from
> `assets/scripts`. They are demo references, not the setup steps for this lab.
> Use module 03 for the Azure environment and module 08 for cleanup. Use synthetic data,
> an approved budget, and a dedicated environment. This lab does not establish
> production readiness by itself.

## 1. Prepare and inspect the source

Use the PowerShell 7.4 or later terminal from module 00. Install Python 3.11 or
later and PostgreSQL 15 or later before starting.

```powershell
Set-Location -LiteralPath $env:LAB_APP_REPO
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
& $env:LAB_SETUP -Module caldova-source
git status --short
$source = Join-Path $env:LAB_APP_REPO 'Scenario1App'
Set-Location -LiteralPath $source
python --version
```

Review `CaldovaClinicalApi/main.py`, `CaldovaClinicalWeb/caldova_home.py`, and
`CaldovaClinicalApi/db/init.sql`.
Identify the `DATABASE_URL` and `CALDOVA_API_URL` settings and the `pharmacy`
schema. Record the inventory fields and filtering behavior to preserve.

Review and commit the downloaded files, then create a branch for this exercise:

```powershell
git add -- .
git commit -m "Add Caldova source application"
git switch -c caldova-source-modernization
```

These commands run inside `Scenario1App`, so they add only that app. Keep unrelated
changes out of this commit. Do not ask Copilot to change the other applications
or the setup scripts.

## 2. Run the app locally

Create one virtual environment for both services:

```powershell
python -m venv CaldovaClinicalApi\.venv
$venvPython = (Resolve-Path CaldovaClinicalApi\.venv\Scripts\python.exe).Path
& $venvPython -m pip install --requirement CaldovaClinicalApi\requirements.txt
& $venvPython -m pip install --requirement CaldovaClinicalWeb\requirements.txt
$pgBin = Read-Host 'Full path to your PostgreSQL bin directory'
& (Join-Path $pgBin 'pg_isready.exe') --host 127.0.0.1 --port 5432
```

PostgreSQL must report that it accepts connections. Create a disposable local
`drugs` database if it does not exist, then initialize it:

```powershell
$databaseExists = & (Join-Path $pgBin 'psql.exe') --host 127.0.0.1 `
    --username postgres --dbname postgres --tuples-only --no-align `
    --command "SELECT 1 FROM pg_database WHERE datname = 'drugs';"
if (($databaseExists -join '').Trim() -ne '1') {
    & (Join-Path $pgBin 'createdb.exe') --host 127.0.0.1 --username postgres drugs
}
& (Join-Path $pgBin 'psql.exe') --host 127.0.0.1 --username postgres `
    --dbname drugs --set ON_ERROR_STOP=1 --file CaldovaClinicalApi\db\init.sql
```

Enter the local PostgreSQL password in the terminal when prompted. The SQL file
preserves existing seed records. Do not point these commands at a customer database.

Start the API in this terminal:

```powershell
$env:DATABASE_URL = Read-Host 'Local SQLAlchemy URL: postgresql+asyncpg://user:password@127.0.0.1:5432/drugs' -MaskInput
Set-Location CaldovaClinicalApi
& $venvPython -m uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

Percent-encode special characters in the URL's username and password. Use only a
local development account. Do not paste credentials into chat or commit them.

In a second PowerShell terminal, enter your repository path again. Settings from
the first terminal are not copied into a new one:

```powershell
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$env:LAB_APP_REPO = (Resolve-Path -LiteralPath (Read-Host 'Full path to your workshop repository')).Path
Set-Location -LiteralPath (Join-Path $env:LAB_APP_REPO 'Scenario1App')
$env:CALDOVA_API_URL = 'http://127.0.0.1:8000'
CaldovaClinicalApi\.venv\Scripts\python.exe -m streamlit run CaldovaClinicalWeb\app.py
```

Open <http://localhost:8501>. Search for a seeded material and exercise the status
filter. Check <http://127.0.0.1:8000/health>,
<http://127.0.0.1:8000/materials>, and <http://127.0.0.1:8000/docs>.
Save responses without credentials so you can compare them after the changes.
A database outage must remain an
HTTP 503 failure, not become a successful response with invented inventory.

**Checkpoint:** Both services work against PostgreSQL, and you have recorded
expected results. Stop both services with Ctrl+C before changing the application.

## 3. Run an assessment and review the plan

In the terminal with your module 03 lab settings, generate names for this app's
separate deployments and ConfigMap. They use the same naming values without
replacing the app from module 04:

```powershell
. (Join-Path $env:LAB_APP_REPO 'assets\scripts\lab-names.ps1')
$sourceNames = Get-LabResourceNames -Application $env:LAB_APPLICATION -Environment $env:LAB_ENVIRONMENT `
    -RegionCode $env:LAB_REGION_CODE -Owner $env:LAB_OWNER -Instance $env:LAB_INSTANCE -Location $env:LAB_LOCATION
$sourceNames | Select-Object SourceApi, SourceWeb, SourceConfig, Namespace, ServiceAccount
```

Open the application folder in VS Code. Use Copilot Chat agent mode to inspect the
Python application; module 07 uses a different assessment flow for Java.

```text
Assess this Scenario1App folder for migration to our approved AKS environment.
Preserve the pharmacy schema, API fields, inventory search, and status filtering.
Identify configuration, dependency, container, identity, and health-probe gaps.
The API currently uses DATABASE_URL and does not implement Entra authentication.
Use the names displayed by the shared naming helper for deployments and config.
Propose small changes, tests, and a way to roll back. Do not modify the
other application copies, provision resources, or deploy. Wait for approval.
```

Check the files Copilot refers to and review its proposed changes. Separate the
changes the app needs from optional extras. Approve one small set of changes at
a time.

## 4. Make and test the changes

Ask Copilot to make the approved changes inside `Scenario1App`:

```text
Generate separate API and Streamlit Dockerfiles and suitable .dockerignore files.
Use non-root containers and explicit dependency installation. Preserve the local
password-based development path, and add an explicit Entra database mode using
Workload ID, TLS verification, and token refresh for new database connections.
Do not store tokens or passwords in source, images, logs, or manifests.
Add database-independent liveness and database-backed readiness, preserving
HTTP 503 for database failures. Generate namespace-scoped Kubernetes resources
with services, probes, and resource requests/limits. Reuse the namespace and
annotated service account from module 03 if that is our approved environment.
Do not overwrite that service account or other apps' deployments.
Use SourceApi and SourceWeb for deployment and service names, and SourceConfig
for the ConfigMap. Apply the agreed owner and naming labels to the new objects.
Add regression checks for inventory responses and database failure behavior.
Show the diff and validation results before any deployment.
```

Workload identity needs both application token acquisition and platform setup:
service-account annotation, pod label, federated credential, and PostgreSQL role
and grants. AKS Automatic's identity defaults do not create database permissions.
Use the [Workload ID overview](https://learn.microsoft.com/azure/aks/workload-identity-overview)
and the identity setup in module 03 to review the generated changes. If you reuse
that setup, keep its namespace and service account names so the federation still
matches. Do not recreate the existing service account or change its identity
annotation. New names require a separate, approved federation setup.

Run the generated tests, then repeat the local checks from step 2. The command
below checks syntax only; it does not replace those tests:

```powershell
Set-Location -LiteralPath (Join-Path $env:LAB_APP_REPO 'Scenario1App')
CaldovaClinicalApi\.venv\Scripts\python.exe -m py_compile `
    CaldovaClinicalApi\main.py CaldovaClinicalWeb\app.py CaldovaClinicalWeb\caldova_home.py
git --no-pager diff -- .
```

**Checkpoint:** Review the generated tests, run them, and confirm the actual
connection code implements identity authentication. Setting environment variables
or adding a service-account annotation alone is not sufficient.

## 5. Build, deploy, and verify

Commit the reviewed changes. Create clean, temporary build contexts from that
commit, following the archive approach in
[Python path in module 04]({% link appmod-lab/4-deploy-application/deploy-application-4-1-python.md %}),
but select the two components under `Scenario1App`. Check that your
`.dockerignore` files exclude virtual environments, local secrets, and database
dumps before uploading either context.

In the terminal with your module 03 settings, set `LAB_API_CONTEXT` and
`LAB_WEB_CONTEXT` to those temporary component folders. Use separate image
repositories, such as `"$($env:LAB_PREFIX)/caldova-source-api"` and
`"$($env:LAB_PREFIX)/caldova-source-web"`, for `LAB_API_REPOSITORY` and
`LAB_WEB_REPOSITORY`.

Follow **step 1 only** of the
[shared deployment exercise]({% link appmod-lab/4-deploy-application/deploy-caldova.md %})
to build the two images and record their digests. Put those digest-based image
references in your generated manifests. Do not run its Caldova deployment
template unless you have checked that your app supports all of its settings,
ports, and probes.

Before applying anything, confirm subscription, cluster context, namespace,
registry pull access, database grants, and approved networking. Review a
server-side dry run of the generated manifests. Have the facilitator approve any
resource or permission changes before executing them.

Verify rollout, events, and logs in your namespace. Port-forward the API and web
services using the commands and participant settings in the deployment exercise,
adapted to your generated service names and ports. Repeat the inventory and filter
checks against Azure PostgreSQL. Record image digests and sanitized evidence.
In your disposable environment, verify database failure produces an unhealthy
readiness result without turning a database outage into a liveness restart loop.

## 6. Optional platform and delivery extensions

If you have time, discuss these extras with your facilitator. None is needed to
complete this exercise:

* For an `HTTPRoute`, obtain the existing Gateway name, namespace, listener, allowed routes, hostname, DNS ownership, and TLS arrangement from the platform owner. Check route `Accepted` and `ResolvedRefs` conditions and test HTTPS. Do not create a public endpoint without approval.

* For Key Vault, identify a real application setting to retrieve, grant only the needed secret access, and validate retrieval without printing the secret. Database Workload ID alone does not require Key Vault.

* For GitHub Actions, use your own workshop repository and the [Azure OIDC guide](https://learn.microsoft.com/azure/developer/github/connect-from-azure-openid-connect). Review the tests, permissions, image digests, deployment approval, and rollback steps. Do not enable a copied workflow with another environment's identifiers.

* If AKS Desktop is available, inspect the same workloads, events, and routes there. Keep command-line validation as evidence when the UI is unavailable.

## Troubleshooting and cleanup

For pip TLS failures, use approved proxy and certificate settings; do not disable
verification. For local HTTP 503 responses, check database readiness, URL encoding,
and schema initialization. For Azure authentication failures, compare the service
account, federation subject, client ID, database role, and TLS configuration.

Stop port forwards and local services, and remove `DATABASE_URL` from the API
terminal with `Remove-Item Env:DATABASE_URL`. Keep only sanitized review evidence.
Keep the shared lab environment for PetClinic in module 07.
After that, follow [module 08]({% link appmod-lab/8-cleanup/index.md %}) for cleanup. Shared
Gateways and platform resources must remain untouched; ask their owner to remove
only the routes, grants, or DNS entries approved for this exercise.

[Next: PetClinic on AKS Automatic]({% link appmod-lab/7-petclinic-aks-automatic/index.md %}) |
[Workshop home]({% link index.md %})