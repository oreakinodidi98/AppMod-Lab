---
title: Test, deploy, and compare Java
description: Test and deploy the Java Caldova implementation against the same PostgreSQL database.
ms.topic: tutorial
parent: Module 03 - Deploy to Azure
nav_order: 3
---

## Goals

Build and deploy the Spring Boot implementation using the same API contract,
PostgreSQL database, and workload identity as the Python implementation. You can
choose this path after [provisioning the environment]({{ site.baseurl }}{% link appmod-lab/3-deploy-to-azure/deploy-to-azure-3-1-environment.md %})
without deploying Python first. If you want to compare both versions, complete
the Python path first, then return here.

## 1. Inspect and test the Java implementation

Use the PowerShell session from environment setup. If it was closed, restore
`LAB_APP_REPO` using the [terminal recovery steps]({{ site.baseurl }}{% link appmod-lab/3-deploy-to-azure/deploy-to-azure-3-1-environment.md %}#restore-terminal-variables-after-a-restart) before downloading files.

Create the folders and download the Java app files directly into your repository. 

```powershell
Set-Location -LiteralPath $env:LAB_APP_REPO
New-Item -ItemType Directory -Path `
  'Java_app\CaldovaClinicalApiJava\src\main\java\com\caldova\clinicalapi\config', `
  'Java_app\CaldovaClinicalApiJava\src\main\java\com\caldova\clinicalapi\inventory', `
  'Java_app\CaldovaClinicalApiJava\src\main\resources', `
  'Java_app\CaldovaClinicalApiJava\src\test\java\com\caldova\clinicalapi\config', `
  'Java_app\CaldovaClinicalApiJava\src\test\java\com\caldova\clinicalapi\inventory', `
  'Java_app\CaldovaClinicalWebJava\src\main\java\com\caldova\clinicalweb\config', `
  'Java_app\CaldovaClinicalWebJava\src\main\java\com\caldova\clinicalweb\inventory', `
  'Java_app\CaldovaClinicalWebJava\src\main\resources\static\css', `
  'Java_app\CaldovaClinicalWebJava\src\main\resources\templates', `
  'Java_app\CaldovaClinicalWebJava\src\test\java\com\caldova\clinicalweb\inventory' `
  -Force | Out-Null

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalApiJava/Dockerfile' `
  -OutFile 'Java_app\CaldovaClinicalApiJava\Dockerfile'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalApiJava/pom.xml' `
  -OutFile 'Java_app\CaldovaClinicalApiJava\pom.xml'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalApiJava/src/main/java/com/caldova/clinicalapi/CaldovaClinicalApiApplication.java' `
  -OutFile 'Java_app\CaldovaClinicalApiJava\src\main\java\com\caldova\clinicalapi\CaldovaClinicalApiApplication.java'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalApiJava/src/main/java/com/caldova/clinicalapi/config/CorsConfiguration.java' `
  -OutFile 'Java_app\CaldovaClinicalApiJava\src\main\java\com\caldova\clinicalapi\config\CorsConfiguration.java'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalApiJava/src/main/java/com/caldova/clinicalapi/config/EntraPostgresConfiguration.java' `
  -OutFile 'Java_app\CaldovaClinicalApiJava\src\main\java\com\caldova\clinicalapi\config\EntraPostgresConfiguration.java'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalApiJava/src/main/java/com/caldova/clinicalapi/config/EntraPostgresDataSource.java' `
  -OutFile 'Java_app\CaldovaClinicalApiJava\src\main\java\com\caldova\clinicalapi\config\EntraPostgresDataSource.java'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalApiJava/src/main/java/com/caldova/clinicalapi/inventory/DemoMaterialRepository.java' `
  -OutFile 'Java_app\CaldovaClinicalApiJava\src\main\java\com\caldova\clinicalapi\inventory\DemoMaterialRepository.java'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalApiJava/src/main/java/com/caldova/clinicalapi/inventory/InventoryController.java' `
  -OutFile 'Java_app\CaldovaClinicalApiJava\src\main\java\com\caldova\clinicalapi\inventory\InventoryController.java'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalApiJava/src/main/java/com/caldova/clinicalapi/inventory/JdbcMaterialRepository.java' `
  -OutFile 'Java_app\CaldovaClinicalApiJava\src\main\java\com\caldova\clinicalapi\inventory\JdbcMaterialRepository.java'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalApiJava/src/main/java/com/caldova/clinicalapi/inventory/Material.java' `
  -OutFile 'Java_app\CaldovaClinicalApiJava\src\main\java\com\caldova\clinicalapi\inventory\Material.java'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalApiJava/src/main/java/com/caldova/clinicalapi/inventory/MaterialRepository.java' `
  -OutFile 'Java_app\CaldovaClinicalApiJava\src\main\java\com\caldova\clinicalapi\inventory\MaterialRepository.java'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalApiJava/src/main/resources/application.yml' `
  -OutFile 'Java_app\CaldovaClinicalApiJava\src\main\resources\application.yml'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalApiJava/src/test/java/com/caldova/clinicalapi/config/EntraPostgresConfigurationTest.java' `
  -OutFile 'Java_app\CaldovaClinicalApiJava\src\test\java\com\caldova\clinicalapi\config\EntraPostgresConfigurationTest.java'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalApiJava/src/test/java/com/caldova/clinicalapi/config/EntraPostgresDataSourceTest.java' `
  -OutFile 'Java_app\CaldovaClinicalApiJava\src\test\java\com\caldova\clinicalapi\config\EntraPostgresDataSourceTest.java'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalApiJava/src/test/java/com/caldova/clinicalapi/inventory/DemoModeIntegrationTest.java' `
  -OutFile 'Java_app\CaldovaClinicalApiJava\src\test\java\com\caldova\clinicalapi\inventory\DemoModeIntegrationTest.java'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalApiJava/src/test/java/com/caldova/clinicalapi/inventory/InventoryControllerTest.java' `
  -OutFile 'Java_app\CaldovaClinicalApiJava\src\test\java\com\caldova\clinicalapi\inventory\InventoryControllerTest.java'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalWebJava/Dockerfile' `
  -OutFile 'Java_app\CaldovaClinicalWebJava\Dockerfile'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalWebJava/pom.xml' `
  -OutFile 'Java_app\CaldovaClinicalWebJava\pom.xml'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalWebJava/src/main/java/com/caldova/clinicalweb/CaldovaClinicalWebApplication.java' `
  -OutFile 'Java_app\CaldovaClinicalWebJava\src\main\java\com\caldova\clinicalweb\CaldovaClinicalWebApplication.java'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalWebJava/src/main/java/com/caldova/clinicalweb/config/ApiClientConfiguration.java' `
  -OutFile 'Java_app\CaldovaClinicalWebJava\src\main\java\com\caldova\clinicalweb\config\ApiClientConfiguration.java'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalWebJava/src/main/java/com/caldova/clinicalweb/inventory/InventoryPageController.java' `
  -OutFile 'Java_app\CaldovaClinicalWebJava\src\main\java\com\caldova\clinicalweb\inventory\InventoryPageController.java'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalWebJava/src/main/java/com/caldova/clinicalweb/inventory/InventoryService.java' `
  -OutFile 'Java_app\CaldovaClinicalWebJava\src\main\java\com\caldova\clinicalweb\inventory\InventoryService.java'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalWebJava/src/main/java/com/caldova/clinicalweb/inventory/InventoryUnavailableException.java' `
  -OutFile 'Java_app\CaldovaClinicalWebJava\src\main\java\com\caldova\clinicalweb\inventory\InventoryUnavailableException.java'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalWebJava/src/main/java/com/caldova/clinicalweb/inventory/Material.java' `
  -OutFile 'Java_app\CaldovaClinicalWebJava\src\main\java\com\caldova\clinicalweb\inventory\Material.java'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalWebJava/src/main/resources/application.yml' `
  -OutFile 'Java_app\CaldovaClinicalWebJava\src\main\resources\application.yml'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalWebJava/src/main/resources/static/css/caldova.css' `
  -OutFile 'Java_app\CaldovaClinicalWebJava\src\main\resources\static\css\caldova.css'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalWebJava/src/main/resources/templates/inventory.html' `
  -OutFile 'Java_app\CaldovaClinicalWebJava\src\main\resources\templates\inventory.html'

Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main/assets/Java_app/CaldovaClinicalWebJava/src/test/java/com/caldova/clinicalweb/inventory/InventoryPageControllerTest.java' `
  -OutFile 'Java_app\CaldovaClinicalWebJava\src\test\java\com\caldova\clinicalweb\inventory\InventoryPageControllerTest.java'
git status --short
```

Review the downloaded files before continuing; the next steps commit them.

Review the API, database configuration, and web application under `Java_app`. If you also downloaded Python, compare the two apps' responsibilities.

Ask Copilot to explain the API contract, database authentication, and tests.
If you are comparing both versions, ask what needs to stay the same when switching.

### Build and test locally

For thi step we will use the original setup terminal. Select JDK 17 before running Maven, then move into the downloaded Java application folder. `mvn --version` shows which Java
version Maven will use.

```powershell
Set-Location -LiteralPath (Join-Path $env:LAB_APP_REPO 'Java_app')
$env:JAVA_HOME = Read-Host 'Full path to your JDK 17 home directory'
$env:PATH = (Join-Path $env:JAVA_HOME 'bin') + [IO.Path]::PathSeparator + $env:PATH
mvn --version
```

Output should confirm that Maven reports Java 17. The first command removes the API's old build output and runs its tests. The next two package the API and web app; Maven also runs their tests as part of packaging. Stop and investigate if any command fails.

```powershell
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
mvn --file CaldovaClinicalApiJava/pom.xml clean test
mvn --file CaldovaClinicalApiJava/pom.xml package
mvn --file CaldovaClinicalWebJava/pom.xml package
```

### Run the API against Azure PostgreSQL

Environment setup already seeded the Azure database and configured your
signed-in user as its Microsoft Entra administrator. Use that same user for
this local check; the managed identity is used later by the AKS pods. The
workstation must still be allowed through the PostgreSQL firewall.

First check that the displayed account and subscription match the ones used
in environment setup:

```powershell
az account show --output table
```

The following commands use the signed-in user's name as the database
principal and select Azure CLI credentials for this local process. They set
the server and database from environment setup and start the API. The Java API
obtains a short-lived Entra token; you do not need a database password.

```powershell
$env:DATABASE_USER = (az ad signed-in-user show --query userPrincipalName --output tsv).Trim()
$env:AZURE_TOKEN_CREDENTIALS = 'AzureCliCredential'
$env:DATA_MODE = 'database'
$env:DATABASE_HOST = $env:POSTGRES_FQDN
$env:DATABASE_PORT = '5432'
$env:DATABASE_NAME = $env:POSTGRES_DATABASE_NAME
$env:SERVER_PORT = '8000'
mvn --file CaldovaClinicalApiJava/pom.xml spring-boot:run
```

If you are not signed in, run `az login`, select the workshop subscription,
and confirm that the account is the Entra administrator used during setup.
The [Java credential chain](https://learn.microsoft.com/azure/developer/java/sdk/authentication/credential-chains) can otherwise choose a different identity before Azure CLI.

Leave the API terminal open. After the API reports that it has started, open
another PowerShell terminal and check these endpoints:

```powershell
Invoke-RestMethod http://localhost:8000/live
Invoke-RestMethod http://localhost:8000/health
Invoke-RestMethod http://localhost:8000/materials
```

`/live` checks that the process responds, `/health` checks the database
connection, and `/materials` returns the seeded inventory. If startup or a
check fails, investigate the identity, database permissions, firewall, and API
logs. Do not use demo mode to claim the database check passed.

### Run the web application

In the second terminal, start from your workshop repository. Select the same
JDK 17 installation; terminals do not share the settings entered above.
`CALDOVA_API_URL` tells the web app where to find the running API, and
`SERVER_PORT` keeps it separate from the API port.

```powershell
Set-Location .\Java_app
$env:JAVA_HOME = Read-Host 'Full path to your JDK 17 home directory'
$env:PATH = (Join-Path $env:JAVA_HOME 'bin') + [IO.Path]::PathSeparator + $env:PATH
mvn --version
$env:CALDOVA_API_URL = 'http://localhost:8000'
$env:SERVER_PORT = '8501'
mvn --file CaldovaClinicalWebJava/pom.xml spring-boot:run
```

Open <http://localhost:8501> and check that the database-backed inventory
appears. Stop the web app and API with Ctrl+C in their respective terminals.

### Try demo mode

Demo mode serves in-memory sample records without connecting to PostgreSQL.
In the original API terminal, start it explicitly after stopping the
database-backed API:

```powershell
$env:DATA_MODE = 'demo'
mvn --file CaldovaClinicalApiJava/pom.xml spring-boot:run
```

In the second terminal, use the same `/live`, `/health`, and `/materials`
commands above. Demo health reports `data_mode: demo`; it does not verify
PostgreSQL. Stop the demo API with Ctrl+C, then remove the local overrides in
the original terminal:

```powershell
Remove-Item Env:DATA_MODE
Remove-Item Env:AZURE_TOKEN_CREDENTIALS
```

### Commit the reviewed files

Return to the repository root. Stage the Java source, project files, and
provided Dockerfiles, but not Maven's `target` output. Check the staged list
before committing so unrelated files are not included. The image build uses
this commit, not uncommitted changes.

```powershell
Set-Location -LiteralPath $env:LAB_APP_REPO
git status --short
git add -- Java_app/CaldovaClinicalApiJava/Dockerfile Java_app/CaldovaClinicalApiJava/pom.xml `
    Java_app/CaldovaClinicalApiJava/src Java_app/CaldovaClinicalWebJava/Dockerfile `
    Java_app/CaldovaClinicalWebJava/pom.xml Java_app/CaldovaClinicalWebJava/src
git diff --cached --name-only
```

If the staged list contains unrelated files, resolve that before committing:

```powershell
git commit -m "Add Java Caldova application"
```

## 2. Build, scan, and publish the Java images

Start Docker Desktop with Linux containers and confirm Trivy is installed as
described in the [prerequisites]({{ site.baseurl }}{% link appmod-lab/0-prerequisites/prerequisite-0-1-technical.md %}).
First create build folders from the committed source. `git archive` copies only
the selected files; separate temporary test copies keep Maven output out of
the image build folders. The subscription check prevents publishing to the
wrong Azure subscription.

```powershell
Set-Location -LiteralPath $env:LAB_APP_REPO
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$env:API_IMAGE = $null
$env:WEB_IMAGE = $null
if ((az account show --query id --output tsv).Trim() -ne $env:AZURE_SUBSCRIPTION_ID) {
    throw 'The active Azure subscription does not match the workshop subscription.'
}
docker version
trivy --version
$buildDir = Join-Path $env:BUILD_ROOT "java-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $buildDir | Out-Null
$sourcePaths = @(
    'Java_app/CaldovaClinicalApiJava/Dockerfile', 'Java_app/CaldovaClinicalApiJava/pom.xml',
    'Java_app/CaldovaClinicalApiJava/src', 'Java_app/CaldovaClinicalWebJava/Dockerfile',
    'Java_app/CaldovaClinicalWebJava/pom.xml', 'Java_app/CaldovaClinicalWebJava/src'
)
git archive --format=tar HEAD -- $sourcePaths | tar -xf - -C $buildDir
git --no-pager -C $env:LAB_APP_REPO log -1 --format='%h %s'
$env:API_BUILD_CONTEXT = Join-Path $buildDir 'Java_app\CaldovaClinicalApiJava'
$env:WEB_BUILD_CONTEXT = Join-Path $buildDir 'Java_app\CaldovaClinicalWebJava'
$testRoot = Join-Path $buildDir 'tests'
New-Item -ItemType Directory -Path $testRoot | Out-Null
Copy-Item -LiteralPath $env:API_BUILD_CONTEXT -Destination (Join-Path $testRoot 'api') -Recurse
Copy-Item -LiteralPath $env:WEB_BUILD_CONTEXT -Destination (Join-Path $testRoot 'web') -Recurse
mvn --file (Join-Path $testRoot 'api\pom.xml') --batch-mode --no-transfer-progress test
mvn --file (Join-Path $testRoot 'web\pom.xml') --batch-mode --no-transfer-progress test
```

`tar` extracts the committed files into a new temporary folder. `git log`
shows the commit used. `Copy-Item` makes separate test folders, and the two
`mvn test` commands check the committed API and web
sources. Both test runs must pass. Review the build folders for sensitive
files before building; the file list is not a substitute for secret scanning.

### Build both images

Use your workshop registry name and a new tag for this build. The tag includes
the source commit and a unique suffix, but tags can still be changed; AKS will
use immutable digests later. Each `docker build` uses its own Dockerfile and
reviewed build folder.

```powershell
$env:API_IMAGE_REPOSITORY = "$env:NAME_PREFIX/java-api"
$env:WEB_IMAGE_REPOSITORY = "$env:NAME_PREFIX/java-web"
$commit = (git rev-parse --short=12 HEAD).Trim()
$tag = '{0}-{1}' -f $commit, [guid]::NewGuid().ToString('N').Substring(0, 12)
$apiTag = '{0}:{1}' -f $env:API_IMAGE_REPOSITORY, $tag
$webTag = '{0}:{1}' -f $env:WEB_IMAGE_REPOSITORY, $tag
$apiImage = '{0}/{1}' -f $env:ACR_LOGIN_SERVER, $apiTag
$webImage = '{0}/{1}' -f $env:ACR_LOGIN_SERVER, $webTag
docker build --file (Join-Path $env:API_BUILD_CONTEXT 'Dockerfile') `
    --tag $apiImage $env:API_BUILD_CONTEXT
docker build --file (Join-Path $env:WEB_BUILD_CONTEXT 'Dockerfile') `
    --tag $webImage $env:WEB_BUILD_CONTEXT
```

### Smoke-test the API image

Ensure local port 8000 is free. Start a temporary container in explicit demo
mode. `--detach` leaves it running while you check it; `--rm` removes it
when stopped. This checks the container, not Azure PostgreSQL.

```powershell
$smokeName = "caldova-java-smoke-$([guid]::NewGuid().ToString('N').Substring(0, 8))"
docker run --rm --detach --name $smokeName `
    --publish 127.0.0.1:8000:8000 --env DATA_MODE=demo $apiImage
```

Run `docker logs $smokeName` and wait for the API to report that it has
started. Then check its process and demo health. Expect `alive`, `healthy`,
and `demo` in the responses. The `finally` block stops and removes this
temporary container even if a check fails.

```powershell
try {
    Invoke-RestMethod http://localhost:8000/live
    Invoke-RestMethod http://localhost:8000/health
}
finally {
    docker rm --force $smokeName
}
```

### Scan both images

Trivy scans each local image for vulnerabilities and secrets. The severity
filter displays High and Critical findings, and `--exit-code 1` makes a
finding fail the command. A scanner error also stops the exercise.

```powershell
trivy image --image-src docker --scanners vuln,secret --severity HIGH,CRITICAL --exit-code 1 $apiImage
trivy image --image-src docker --scanners vuln,secret --severity HIGH,CRITICAL --exit-code 1 $webImage
```

If the first scan stops the block, run the second separately to review its
findings. If either fails, do not publish or deploy. Review and test approved
fixes, commit them, then repeat step 2 to create fresh build folders and a new
tag. If a finding cannot be resolved, stop and ask the facilitator. Do not
suppress findings to pass.

### Publish and verify the images

`az acr login` authenticates Docker to your workshop registry. The push
commands upload the same two images that passed the local scans.

```powershell
az acr login --name $env:ACR_NAME
docker push $apiImage
docker push $webImage
```

Look up each pushed image's digest and scan that exact registry artifact.
Only after both scans pass are the digest-based references saved for
deployment. The Azure CLI manifest command is in preview.

```powershell
$env:API_IMAGE = $null
$env:WEB_IMAGE = $null
$apiDigest = (az acr manifest show-metadata --registry $env:ACR_NAME `
    --name $apiTag --query digest --output tsv).Trim()
$webDigest = (az acr manifest show-metadata --registry $env:ACR_NAME `
    --name $webTag --query digest --output tsv).Trim()
$apiDigestImage = '{0}/{1}@{2}' -f $env:ACR_LOGIN_SERVER, $env:API_IMAGE_REPOSITORY, $apiDigest
$webDigestImage = '{0}/{1}@{2}' -f $env:ACR_LOGIN_SERVER, $env:WEB_IMAGE_REPOSITORY, $webDigest
trivy image --image-src remote --scanners vuln,secret --severity HIGH,CRITICAL --exit-code 1 $apiDigestImage
trivy image --image-src remote --scanners vuln,secret --severity HIGH,CRITICAL --exit-code 1 $webDigestImage
$env:API_IMAGE = $apiDigestImage
$env:WEB_IMAGE = $webDigestImage
"API image: $env:API_IMAGE"
"Web image: $env:WEB_IMAGE"
```

If either registry scan fails, stop and repeat the build and scans after
fixing the issue. Do not deploy an earlier image reference.

### Deploy the scanned images

If Python port forwards are still running, stop them with Ctrl+C. Follow
**step 2 onward** of the
[shared deployment exercise]({{ site.baseurl }}{% link appmod-lab/3-deploy-to-azure/deploy-to-azure-3-4-deploy.md %}#2-configure-and-deploy),
then return here. Do not run its build step; it would create different,
unscanned images. The shared step updates the existing deployments if Python
was deployed, or creates them otherwise. Start new port forwards for the Java
pods.

The Java API also has a `demo` data mode, but this exercise deliberately uses
`DATA_MODE=database`. Demo mode is synthetic in-memory data, not a fallback or proof
that PostgreSQL and workload identity work.

## 3. Compare behavior (optional)

If you completed the Python path in this PowerShell session, compare the complete
inventory response from both implementations. Otherwise, skip this step.

```powershell
$javaInventorySnapshot = @(
    $materials | Sort-Object lot_number |
        Select-Object id, name, category, lot_number, quantity, unit, status, location, expiry_date, image_url
)
$pythonJson = ConvertTo-Json -InputObject $pythonInventorySnapshot -Depth 4 -Compress
$javaJson = ConvertTo-Json -InputObject $javaInventorySnapshot -Depth 4 -Compress
$pythonJson -ceq $javaJson
```

The result should be `True`. If it is `False`, investigate the difference
before continuing. Compare the browser experience and the code paths as well. A matching sample
response does not prove that the implementations behave identically for all inputs
or failures.

### Build the API in ACR

After deployment, you can also try an ACR-hosted build. This uploads the
reviewed API build folder, builds it in ACR, and publishes a **separate**
image under a new tag. It may incur additional cost.

```powershell
$exampleTag = "example-$([guid]::NewGuid().ToString('N').Substring(0, 12))"
az acr build --resource-group $env:RG_NAME --registry $env:ACR_NAME `
    --image ('{0}:{1}' -f $env:API_IMAGE_REPOSITORY, $exampleTag) `
    --file Dockerfile $env:API_BUILD_CONTEXT
```

This image is not the locally scanned image and is not used in the deployment
above. It would need its own scan and digest verification before deployment.

## Checkpoint

The Java tests pass, both Java pods are ready, and the API and web application show
the seeded database inventory. If you ran both paths, you have compared their
responses and can identify the evidence you would need for a production migration.

[Next: operate and improve]({{ site.baseurl }}{% link appmod-lab/4-operate-and-improve/index.md %}) |
[Workshop home]({{ site.baseurl }}{% link index.md %})
