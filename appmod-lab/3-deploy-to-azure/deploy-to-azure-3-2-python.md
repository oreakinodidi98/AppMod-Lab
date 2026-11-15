---
title: Build and verify Python
description: Build the Python Caldova API and web application and verify them on AKS.
ms.topic: tutorial
parent: Module 03 - Deploy to Azure
nav_order: 2
---

## Goals

Deploy the existing Python implementation to the environment from
[environment setup]({{ site.baseurl }}{% link appmod-lab/3-deploy-to-azure/deploy-to-azure-3-1-environment.md %}). Verify that the application uses the
seeded PostgreSQL database through Microsoft Entra Workload ID.

## 1. Understand the application

Use the PowerShell session from environment setup. If it was closed, restore
`LAB_APP_REPO` using the
[terminal recovery steps]({{ site.baseurl }}{% link appmod-lab/3-deploy-to-azure/deploy-to-azure-3-1-environment.md %}#restore-terminal-variables-after-a-restart)
before downloading files.

Create the folders and download the Python app files directly into your
repository. These commands do not download the SQL seed again.
Downloads replace existing files; skip files you already have or have edited.

```powershell
Set-Location -LiteralPath $env:LAB_APP_REPO
New-Item -ItemType Directory -Path 'Python_app\CaldovaClinicalApi', 'Python_app\CaldovaClinicalWeb' -Force | Out-Null

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Python_app/CaldovaClinicalApi/Dockerfile' `
  -OutFile 'Python_app\CaldovaClinicalApi\Dockerfile'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Python_app/CaldovaClinicalApi/main.py' `
  -OutFile 'Python_app\CaldovaClinicalApi\main.py'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Python_app/CaldovaClinicalApi/requirements.txt' `
  -OutFile 'Python_app\CaldovaClinicalApi\requirements.txt'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Python_app/CaldovaClinicalWeb/app.py' `
  -OutFile 'Python_app\CaldovaClinicalWeb\app.py'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Python_app/CaldovaClinicalWeb/caldova_home.py' `
  -OutFile 'Python_app\CaldovaClinicalWeb\caldova_home.py'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Python_app/CaldovaClinicalWeb/Dockerfile' `
  -OutFile 'Python_app\CaldovaClinicalWeb\Dockerfile'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Python_app/CaldovaClinicalWeb/requirements.txt' `
  -OutFile 'Python_app\CaldovaClinicalWeb\requirements.txt'
git status --short
```

Review the downloaded files before continuing; Step 2 commits them.

Review `Python_app/CaldovaClinicalApi/main.py`, the web application in `Python_app/CaldovaClinicalWeb/caldova_home.py`, and the database seed downloaded during environment setup at `Python_app/CaldovaClinicalApi/db/init.sql`.

Trace a request from the browser to the web application, the `/materials` API, and PostgreSQL. Find the separate liveness and database-readiness endpoints. Identify how the API gets a database token without storing a database password.

You can ask Copilot to explain this flow using the files above. Review its answer against the code, and do not include tokens, customer data, or connection secrets in the prompt.

### Run the Python app locally

These steps let you test the API and web app on your workstation before
deploying to AKS. They use a separate **local** PostgreSQL database and a
local password, not the Azure database or workload identity from environment
setup. Use [Python 3.11](https://www.python.org/downloads/windows/) and a
running local [PostgreSQL 15 or later server](https://www.postgresql.org/download/windows/)
with its command-line tools. Use an approved package source and a disposable
database with synthetic data.

#### 1. Create the Python environment

From your workshop repository, create one virtual environment for both
applications. This keeps their packages separate from your system Python.
Then install the dependencies listed by the API and web app:

```powershell
Set-Location -LiteralPath $env:LAB_APP_REPO
python --version
python -m venv Python_app\CaldovaClinicalApi\.venv
$venvPython = Resolve-Path Python_app\CaldovaClinicalApi\.venv\Scripts\python.exe
& $venvPython -m pip install --requirement Python_app\CaldovaClinicalApi\requirements.txt
& $venvPython -m pip install --requirement Python_app\CaldovaClinicalWeb\requirements.txt
```

If installation fails, check your organization's package-source and network
settings before changing pip configuration.

#### 2. Check the Python files

Compile the files without starting either application. This checks Python
syntax; it does not test the database connection.

```powershell
& $venvPython -m py_compile Python_app\CaldovaClinicalApi\main.py
& $venvPython -m py_compile Python_app\CaldovaClinicalWeb\app.py Python_app\CaldovaClinicalWeb\caldova_home.py
```

#### 3. Initialize the local database

Enter the full path to your local PostgreSQL `bin` folder, then check that the
server accepts connections:

```powershell
$pgBin = Read-Host 'Full path to your local PostgreSQL bin directory'
& "$pgBin\pg_isready.exe" --host 127.0.0.1 --port 5432
```

Check whether a local database named `drugs` already exists. The command may
prompt for the local `postgres` account password:

```powershell
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
& "$pgBin\psql.exe" --host 127.0.0.1 --port 5432 `
  --username postgres --dbname postgres --tuples-only --no-align `
  --command "SELECT 1 FROM pg_database WHERE datname = 'drugs';"
```

If the command fails, stop and investigate. If the result is `1`, stop and
check its owner and contents. Do not change an unrelated database. If the
check succeeds and returns no row, create the disposable database:

```powershell
& "$pgBin\createdb.exe" --host 127.0.0.1 --port 5432 --username postgres drugs
```

Only after the database is created successfully, load the SQL seed downloaded
during environment setup:

```powershell
& "$pgBin\psql.exe" --host 127.0.0.1 --port 5432 `
  --username postgres --dbname drugs --set ON_ERROR_STOP=1 `
  --file Python_app\CaldovaClinicalApi\db\init.sql
```

The seed creates the `pharmacy` schema, including the materials, locations,
inventory lots, and studies tables. It preserves existing seed records on
retry. Stop and investigate if initialization fails, and review the database
before applying the seed again.

#### 4. Start and check the API

Enter the SQLAlchemy connection URL for your local PostgreSQL account when
prompted. Input is masked. Percent-encode special characters in the username
and password, and never commit or share the URL.

```powershell
$env:DATABASE_URL = Read-Host 'Local URL: postgresql+asyncpg://user:password@127.0.0.1:5432/drugs' -MaskInput
$env:DATABASE_AUTH_MODE = 'password'
Set-Location Python_app\CaldovaClinicalApi
& $venvPython -m uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

Keep this terminal open while the API runs. In your browser, check
<http://127.0.0.1:8000/health>, <http://127.0.0.1:8000/materials>, and
<http://127.0.0.1:8000/docs>. If the database is unavailable, the health
or inventory endpoint returns HTTP 503; check the local PostgreSQL service,
connection URL, and initialized schema.

#### 5. Start and check the web app

Open a second PowerShell terminal in your workshop repository. Set the API
address and start Streamlit using the same virtual environment:

```powershell
$env:LAB_APP_REPO = git rev-parse --show-toplevel
Set-Location -LiteralPath $env:LAB_APP_REPO
$env:CALDOVA_API_URL = 'http://127.0.0.1:8000'
Python_app\CaldovaClinicalApi\.venv\Scripts\python.exe -m streamlit run Python_app\CaldovaClinicalWeb\app.py
```

Open <http://localhost:8501> and try searching and filtering the inventory.
When finished, stop both applications with Ctrl+C. In the API terminal, remove
the local connection URL with `Remove-Item Env:DATABASE_URL`. Return to your
original environment setup terminal for the AKS build and deployment below.

## 2. Challenge: Create a Dockerfile with Copilot

Now that the app runs locally, use Copilot to explore how to package the API
for a container. You will create a practice Dockerfile and compare it with the
one provided for the workshop. The practice file is not used for deployment
or committed.

Open your workshop repository in VS Code. If
`Python_app/CaldovaClinicalApi/Dockerfile.challenge` already exists, review it
before proceeding so you do not overwrite your work. In Copilot Chat, use agent
mode and provide this prompt:

```text
Review Python_app/CaldovaClinicalApi/main.py and requirements.txt.
Create a practice Dockerfile named Python_app/CaldovaClinicalApi/Dockerfile.challenge
for this FastAPI application.

Use Python 3.11, install the listed dependencies, run as a non-root user,
listen on port 8000, and include a health check using the API's liveness endpoint.
Do not put credentials in the image. Explain each instruction and any assumptions.

Do not read, overwrite, or change the provided Dockerfiles. Do not modify any
other files, build an image, or commit changes.
```

Review the generated file and Copilot's explanation. Compare it with the
provided `Python_app/CaldovaClinicalApi/Dockerfile`: how do they install
dependencies, start the API, run as a non-root user, and check health? Review
the provided web Dockerfile too. The provided files remain the ones used for
the workshop deployment.

### Commit the workshop files

Commit only the reviewed application files and the provided Dockerfiles.
The practice Dockerfile, local virtual environment, and other local files
should not be committed. Check for any unrelated staged changes before
committing; the build uses committed files, not uncommitted changes.

```powershell
Set-Location -LiteralPath $env:LAB_APP_REPO
git status --short
git add -- Python_app/CaldovaClinicalApi/Dockerfile Python_app/CaldovaClinicalApi/main.py `
    Python_app/CaldovaClinicalApi/requirements.txt Python_app/CaldovaClinicalWeb/Dockerfile `
    Python_app/CaldovaClinicalWeb/app.py Python_app/CaldovaClinicalWeb/caldova_home.py `
    Python_app/CaldovaClinicalWeb/requirements.txt
git diff --cached --name-only
```

Check that the staged list contains only the intended workshop files before
committing. If it contains other files, resolve that before continuing.

```powershell
git commit -m "Add Python Caldova application"
```

## 3. Build, scan, and publish the Python images

Choose either the commands or the Copilot path below. Both build the provided
API and web Dockerfiles, scan the images locally, and publish them to your
workshop registry only after the scans pass.

You need Docker Desktop running with Linux containers and Trivy available on
your command path. Check the [prerequisites]({{ site.baseurl }}{% link appmod-lab/0-prerequisites/prerequisite-0-1-technical.md %}) before continuing.

### Set up the build

Run this in the original environment setup terminal. The temporary folders
contain only the committed files needed by the two Dockerfiles, not your local
virtual environment, database seed, or practice Dockerfile. This prevents
those local files from being included in the images. Check that the displayed
subscription matches your workshop subscription and that the registry and
build settings are present.

```powershell
Set-Location -LiteralPath $env:LAB_APP_REPO
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$env:API_IMAGE = $null
$env:WEB_IMAGE = $null
az account show --query "{Name:name,Id:id}" --output table
"Workshop subscription ID: $env:AZURE_SUBSCRIPTION_ID"
"Registry: $env:ACR_NAME ($env:ACR_LOGIN_SERVER)"
"Build root: $env:BUILD_ROOT"
"Name prefix: $env:NAME_PREFIX"
docker version
trivy --version
```

Stop if a value is missing or the subscription is wrong. Restore the
environment setup variables or select the correct subscription before
continuing.

Create the build folders and image names. The new `Python_app` folder must not
already exist; `New-Item` stops rather than replacing it.

```powershell
New-Item -ItemType Directory -Path $env:BUILD_ROOT -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $env:BUILD_ROOT 'Python_app') | Out-Null
git archive --format=tar HEAD -- `
    Python_app/CaldovaClinicalApi/Dockerfile `
    Python_app/CaldovaClinicalApi/main.py `
    Python_app/CaldovaClinicalApi/requirements.txt `
    Python_app/CaldovaClinicalWeb/Dockerfile `
    Python_app/CaldovaClinicalWeb/app.py `
    Python_app/CaldovaClinicalWeb/caldova_home.py `
    Python_app/CaldovaClinicalWeb/requirements.txt |
    tar -xf - -C $env:BUILD_ROOT

$env:API_BUILD_CONTEXT = Join-Path $env:BUILD_ROOT 'Python_app\CaldovaClinicalApi'
$env:WEB_BUILD_CONTEXT = Join-Path $env:BUILD_ROOT 'Python_app\CaldovaClinicalWeb'
$env:API_IMAGE_REPOSITORY = "$env:NAME_PREFIX/python-api"
$env:WEB_IMAGE_REPOSITORY = "$env:NAME_PREFIX/python-web"
$tag = "lab-$([guid]::NewGuid().ToString('N').Substring(0, 12))"
$apiTag = '{0}:{1}' -f $env:API_IMAGE_REPOSITORY, $tag
$webTag = '{0}:{1}' -f $env:WEB_IMAGE_REPOSITORY, $tag
$apiImage = '{0}/{1}' -f $env:ACR_LOGIN_SERVER, $apiTag
$webImage = '{0}/{1}' -f $env:ACR_LOGIN_SERVER, $webTag
"API context: $env:API_BUILD_CONTEXT"
"Web context: $env:WEB_BUILD_CONTEXT"
"API image: $apiImage"
"Web image: $webImage"
"Registry name: $env:ACR_NAME"
```

Review the two build folders. If they already exist, inspect them before
removing or replacing them; the command will not overwrite them. The file
allowlist does not replace secret scanning. The tag is unique to this attempt;
deployment will use registry digests rather than treating tags as immutable.

### Option 1: Run the commands

Build both images locally from the reviewed folders:

```powershell
docker build --file (Join-Path $env:API_BUILD_CONTEXT 'Dockerfile') `
    --tag $apiImage $env:API_BUILD_CONTEXT
docker build --file (Join-Path $env:WEB_BUILD_CONTEXT 'Dockerfile') `
    --tag $webImage $env:WEB_BUILD_CONTEXT
```

Scan both images for vulnerabilities and secrets. Trivy returns a nonzero
exit code if it finds a High or Critical issue or cannot complete the scan.
Run both scans and review their results. If the first scan stops the block,
run the second command separately to see its findings too:

```powershell
trivy image --image-src docker --scanners vuln,secret --severity HIGH,CRITICAL --exit-code 1 $apiImage
trivy image --image-src docker --scanners vuln,secret --severity HIGH,CRITICAL --exit-code 1 $webImage
```

If either scan fails, do not publish or deploy. Review the findings, make and
test approved fixes, commit the changed application files, then create fresh
build folders and rebuild and rescan **both** images. Inspect the old temporary
`Python_app` build folder before removing or moving it. Rerun **Set up the
build** to generate a new tag. If a finding cannot be resolved, stop and ask
the facilitator; do not suppress it to pass the exercise.

After both scans pass, sign in to ACR and push the same images:

```powershell
az acr login --name $env:ACR_NAME
docker push $apiImage
docker push $webImage
```

### Option 2: Ask Copilot to execute

In VS Code Copilot Chat, select agent mode. Provide the displayed context paths,
image names, and registry name when asked. Do not share credentials, tokens, or
local database connection strings. Use this prompt:

```text
Help me build, scan, and publish the Python Caldova API and web images.
Ask me for the two reviewed build-context paths, the two full image tags,
and my workshop ACR name if you cannot see them.

Use the provided Dockerfile in each context and build both images locally.
Run Trivy vulnerability and secret scans on both local images with severity
HIGH,CRITICAL and a nonzero exit code for findings. Show me the results.
If either scan fails, stop: propose fixes for my review, but do not suppress
findings or publish. After approved fixes are committed, use fresh build
contexts and a new tag, then rebuild and rescan both images.

Only when both scans pass, sign in with az acr login and push those exact
images to my workshop ACR. Ask for my approval before making code changes
or pushing. Do not deploy, create resources, or expose credentials.
Report the commands and results.
```

Review Copilot's commands and scan results before approving any changes or
pushes. If it cannot execute a step, stop and use the command option or resolve
the error. Keep the original setup terminal open for the final checks below.

### Verify the published images

After either option succeeds, run this in the original setup terminal. It
looks up each pushed image's digest and scans that exact registry artifact
again before recording the references used by AKS. This checks what will
actually be deployed. The Azure CLI manifest command is in preview.

```powershell
$env:API_IMAGE = $null
$env:WEB_IMAGE = $null
az acr login --name $env:ACR_NAME
$apiDigest = (az acr manifest show-metadata --registry $env:ACR_NAME `
    --name $apiTag --query digest --output tsv).Trim()
$webDigest = (az acr manifest show-metadata --registry $env:ACR_NAME `
    --name $webTag --query digest --output tsv).Trim()
"API digest: $apiDigest"
"Web digest: $webDigest"
```

Check that each digest starts with `sha256:` followed by 64 hexadecimal
characters. Stop if either is missing or incomplete. Then scan the two
digest references:

```powershell
$apiDigestImage = '{0}/{1}@{2}' -f $env:ACR_LOGIN_SERVER, $env:API_IMAGE_REPOSITORY, $apiDigest
$webDigestImage = '{0}/{1}@{2}' -f $env:ACR_LOGIN_SERVER, $env:WEB_IMAGE_REPOSITORY, $webDigest
trivy image --image-src remote --scanners vuln,secret --severity HIGH,CRITICAL --exit-code 1 $apiDigestImage
trivy image --image-src remote --scanners vuln,secret --severity HIGH,CRITICAL --exit-code 1 $webDigestImage
$env:API_IMAGE = $apiDigestImage
$env:WEB_IMAGE = $webDigestImage
"API image: $env:API_IMAGE"
"Web image: $env:WEB_IMAGE"
```

If either registry scan fails or reports High or Critical findings, stop. Fix
the issue and repeat the build, local scans, and push with a new tag. Do not
deploy using an earlier image reference.

Once both registry scans pass, follow **step 2 onward** of the
[shared deployment exercise]({{ site.baseurl }}{% link appmod-lab/3-deploy-to-azure/deploy-to-azure-3-4-deploy.md %}#2-configure-and-deploy),
then return here. Do not run its build step: it would create different,
unscanned images. The Python web application caches inventory responses for up
to 30 seconds.

## 4. Record the comparison baseline (optional)

If you also want to try Java, save the returned synthetic inventory in this
PowerShell session after the shared exercise succeeds. Otherwise, continue to
module 04:

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

[Next: operate and improve]({{ site.baseurl }}{% link appmod-lab/4-operate-and-improve/index.md %}) |
[Compare with Java]({{ site.baseurl }}{% link appmod-lab/3-deploy-to-azure/deploy-to-azure-3-3-java.md %}) |
[Workshop home]({{ site.baseurl }}{% link index.md %})
