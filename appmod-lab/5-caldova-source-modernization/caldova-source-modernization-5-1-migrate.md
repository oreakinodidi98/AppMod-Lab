---
title: Run, assess, and modernize Caldova
description: Run Caldova locally, then use Copilot to prepare and test its AKS migration.
ms.topic: tutorial
parent: Module 05 - Modernize Caldova
nav_order: 1
---

## Goals

Run the Python Caldova app locally, then use Copilot to prepare it for AKS.
Unlike module 03, this exercise starts without Dockerfiles,
Kubernetes manifests, or passwordless database support. You generate and validate
those changes rather than starting with the already-modernized implementation.

Allow 90-120 minutes, plus time to create the Azure environment. Complete
[module 00]({{ site.baseurl }}{% link appmod-lab/0-prerequisites/index.md %}) first. Before deploying, complete
[module 03]({{ site.baseurl }}{% link appmod-lab/3-deploy-to-azure/index.md %}), or ask your facilitator for a dedicated,
approved environment with equivalent registry, database, and identity access.

The direct downloads below put the starter app into `Scenario1App` in your
repository. Keep all changes inside
`Scenario1App`; do not overwrite `Python_app`, which module 03 uses.

> [!IMPORTANT]
> Do not run `AutomaticSetup.ps1`, `ClassicSetup.ps1`, or `cleanup.ps1` from
> `assets/scripts`. They are demo references, not the setup steps for this lab.
> Use module 03 for the Azure environment and module 07 for cleanup. Use synthetic data,
> an approved budget, and a dedicated environment. This lab does not establish
> production readiness by itself.

## 1. Prepare and inspect the source

Use the PowerShell 7.4 or later terminal from module 00. Install Python 3.11 or
later and PostgreSQL 15 or later before starting.
If you restarted PowerShell, restore `LAB_APP_REPO` using
[module 00]({{ site.baseurl }}{% link appmod-lab/0-prerequisites/prerequisite-0-1-technical.md %}#create-your-workshop-repository).
Downloads replace existing files; skip this block if you already downloaded
the app, especially if you have started modernizing it.

```powershell
Set-Location -LiteralPath $env:LAB_APP_REPO
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
New-Item -ItemType Directory -Path `
  'Scenario1App\CaldovaClinicalApi\db', `
  'Scenario1App\CaldovaClinicalWeb' `
  -Force | Out-Null

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Scenario1App/.gitignore' `
  -OutFile 'Scenario1App\.gitignore'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Scenario1App/CaldovaClinicalApi/main.py' `
  -OutFile 'Scenario1App\CaldovaClinicalApi\main.py'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Scenario1App/CaldovaClinicalApi/requirements.txt' `
  -OutFile 'Scenario1App\CaldovaClinicalApi\requirements.txt'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Scenario1App/CaldovaClinicalApi/db/init.sql' `
  -OutFile 'Scenario1App\CaldovaClinicalApi\db\init.sql'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Scenario1App/CaldovaClinicalWeb/app.py' `
  -OutFile 'Scenario1App\CaldovaClinicalWeb\app.py'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Scenario1App/CaldovaClinicalWeb/caldova_home.py' `
  -OutFile 'Scenario1App\CaldovaClinicalWeb\caldova_home.py'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Scenario1App/CaldovaClinicalWeb/requirements.txt' `
  -OutFile 'Scenario1App\CaldovaClinicalWeb\requirements.txt'
git status --short
```

Move into the downloaded application and check Python:

```powershell
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

PostgreSQL must report that it accepts connections. Check whether a local
database named `drugs` already exists:

```powershell
& (Join-Path $pgBin 'psql.exe') --host 127.0.0.1 `
    --username postgres --dbname postgres --tuples-only --no-align `
    --command "SELECT 1 FROM pg_database WHERE datname = 'drugs';"
```

If the result is `1`, stop and check its owner and contents. Do not initialize
an unrelated database. Otherwise, create the disposable database and initialize it:

```powershell
& (Join-Path $pgBin 'createdb.exe') --host 127.0.0.1 --username postgres drugs
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

Open a second PowerShell terminal inside your cloned workshop repository.
Settings from the first terminal are not copied into a new one, so find and
save the repository path again before starting the web app:

```powershell
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$env:LAB_APP_REPO = $null
$repoRoot = git rev-parse --show-toplevel
$env:LAB_APP_REPO = (Resolve-Path -LiteralPath $repoRoot).Path
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

Use the PowerShell terminal from module 03 so its environment settings remain
available. Give this source-modernization exercise separate deployments and a
ConfigMap, while reusing its approved namespace and service account:

```powershell
$env:SOURCE_API_NAME = "apisrc-$env:NAME_PREFIX"
$env:SOURCE_WEB_NAME = "websrc-$env:NAME_PREFIX"
$env:SOURCE_CONFIG_NAME = "cfgsrc-$env:NAME_PREFIX"
"Source API: $env:SOURCE_API_NAME"
"Source web: $env:SOURCE_WEB_NAME"
"Source ConfigMap: $env:SOURCE_CONFIG_NAME"
"Namespace: $env:MANAGED_NAMESPACE_NAME"
"Service account: $env:SERVICE_ACCOUNT_NAME"
```

Open the application folder in VS Code. Use Copilot Chat agent mode to inspect the
Python application; module 06 uses a different assessment flow for Java.

```text
Assess this Scenario1App folder for migration to our approved AKS environment.
Preserve the pharmacy schema, API fields, inventory search, and status filtering.
Identify configuration, dependency, container, identity, and health-probe gaps.
The API currently uses DATABASE_URL and does not implement Entra authentication.
Use the displayed source API, web, and ConfigMap names.
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
Use the displayed source API and web names for deployments and services, and the
displayed source ConfigMap name. Apply the agreed owner and naming labels.
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

Commit the reviewed changes, then create temporary build contexts from the
committed source. These commands copy only the API and web application folders
into the temporary build directory:

```powershell
Set-Location -LiteralPath $env:LAB_APP_REPO
New-Item -ItemType Directory -Path $env:BUILD_ROOT -Force | Out-Null
if (Test-Path -LiteralPath (Join-Path $env:BUILD_ROOT 'Scenario1App')) {
    throw 'Source build contexts already exist. Review them before recreating them.'
}
$archive = Join-Path $env:BUILD_ROOT 'source-caldova.tar'
git archive --format=tar --output $archive HEAD -- `
    Scenario1App/CaldovaClinicalApi Scenario1App/CaldovaClinicalWeb
tar -xf $archive -C $env:BUILD_ROOT
Remove-Item -LiteralPath $archive
$env:API_BUILD_CONTEXT = Join-Path $env:BUILD_ROOT 'Scenario1App\CaldovaClinicalApi'
$env:WEB_BUILD_CONTEXT = Join-Path $env:BUILD_ROOT 'Scenario1App\CaldovaClinicalWeb'
$env:API_IMAGE_REPOSITORY = "$env:NAME_PREFIX/caldova-source-api"
$env:WEB_IMAGE_REPOSITORY = "$env:NAME_PREFIX/caldova-source-web"
```

Check that both `.dockerignore` files exclude virtual environments, local
secrets, and database dumps before uploading either context.

Follow **step 1 only** of the
[shared deployment exercise]({{ site.baseurl }}{% link appmod-lab/3-deploy-to-azure/deploy-to-azure-3-4-deploy.md %})
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
Keep the shared lab environment for PetClinic in module 06.
After that, follow [module 07]({{ site.baseurl }}{% link appmod-lab/7-cleanup/index.md %}) for cleanup. Shared
Gateways and platform resources must remain untouched; ask their owner to remove
only the routes, grants, or DNS entries approved for this exercise.

[Next: PetClinic on AKS Automatic]({{ site.baseurl }}{% link appmod-lab/6-petclinic-aks-automatic/index.md %}) |
[Workshop home]({{ site.baseurl }}{% link index.md %})