---
title: Test, deploy, and compare Java
description: Test and deploy the Java Caldova implementation against the same PostgreSQL database.
ms.topic: tutorial
parent: Module 04 - Deploy the application to Azure
nav_order: 2
---

## Goals

Build and deploy the Spring Boot implementation using the same API contract,
PostgreSQL database, and workload identity as the Python implementation. You can
choose this path after [module 03]({{ site.baseurl }}{% link appmod-lab/3-azure-environment/index.md %})
without deploying Python first. If you want to compare both versions, complete
the Python path first, then return here.

## 1. Inspect and test the Java implementation

Download the Java app into your workshop repository:

```powershell
Set-Location -LiteralPath $env:LAB_APP_REPO
& $env:LAB_SETUP -Module java
git status --short
```

Review the API, database configuration, and web application under `Java_app`.
If you also downloaded Python, compare the two apps' responsibilities.

Ask Copilot to explain the API contract, database authentication, and tests.
If you are comparing both versions, ask what needs to stay the same when switching.
Review its answer against the code, without including tokens or customer data.

Commit the reviewed app files, then create the build contexts from that commit.
The archive uses committed files, not uncommitted changes.

```powershell
git add -- Java_app
git commit -m "Add Java Caldova application"
```

Select your JDK 17 installation. Run the existing tests from temporary copies so
Maven output is not included in the container build contexts:

```powershell
Set-Location -LiteralPath $env:LAB_APP_REPO
$env:JAVA_HOME = Read-Host 'Full path to your JDK 17 home directory'
$env:PATH = (Join-Path $env:JAVA_HOME 'bin') + [IO.Path]::PathSeparator + $env:PATH
mvn --version

if (Test-Path -LiteralPath (Join-Path $env:LAB_BUILD_ROOT 'Java_app')) {
    throw 'Java build contexts already exist. Review them before recreating them.'
}
$archive = Join-Path $env:LAB_BUILD_ROOT 'java-source.tar'
$sourcePaths = @(
    'Java_app/CaldovaClinicalApiJava/Dockerfile', 'Java_app/CaldovaClinicalApiJava/pom.xml',
    'Java_app/CaldovaClinicalApiJava/src', 'Java_app/CaldovaClinicalWebJava/Dockerfile',
    'Java_app/CaldovaClinicalWebJava/pom.xml', 'Java_app/CaldovaClinicalWebJava/src'
)
git -C $env:LAB_APP_REPO archive --format=tar --output $archive HEAD -- $sourcePaths
tar -xf $archive -C $env:LAB_BUILD_ROOT
Remove-Item -LiteralPath $archive
git --no-pager -C $env:LAB_APP_REPO log -1 --format='%h %s'
$env:LAB_API_CONTEXT = Join-Path $env:LAB_BUILD_ROOT 'Java_app\CaldovaClinicalApiJava'
$env:LAB_WEB_CONTEXT = Join-Path $env:LAB_BUILD_ROOT 'Java_app\CaldovaClinicalWebJava'
$testRoot = Join-Path $env:LAB_BUILD_ROOT "java-tests-$([guid]::NewGuid().ToString('N').Substring(0, 8))"
New-Item -ItemType Directory -Path $testRoot | Out-Null
Copy-Item -LiteralPath $env:LAB_API_CONTEXT -Destination (Join-Path $testRoot 'api') -Recurse
Copy-Item -LiteralPath $env:LAB_WEB_CONTEXT -Destination (Join-Path $testRoot 'web') -Recurse
mvn --file (Join-Path $testRoot 'api\pom.xml') --batch-mode --no-transfer-progress test
mvn --file (Join-Path $testRoot 'web\pom.xml') --batch-mode --no-transfer-progress test
```

Confirm that Maven reports Java 17 and that both test runs pass. Investigate a
failure before deploying. These tests complement, but do not replace, the
database-backed checks on AKS. Review both build contexts for sensitive files
before uploading them; the file list is not a substitute for secret scanning.

## 2. Select and deploy Java

```powershell
$env:LAB_API_REPOSITORY = "$($env:LAB_PREFIX)/java-api"
$env:LAB_WEB_REPOSITORY = "$($env:LAB_PREFIX)/java-web"
```

If the Python port forwards are still running, stop them with Ctrl+C. Follow the
[shared build and deployment exercise]({{ site.baseurl }}{% link appmod-lab/4-deploy-application/deploy-caldova.md %}),
then return here. If you already deployed Python, this updates the same
Kubernetes deployments to the Java images. Otherwise, it creates the deployments.
The database and identity from module 03 remain in place. Open new port forwards
for the Java pods as described in that exercise.

The Java API also has a `demo` data mode, but this exercise deliberately uses
`DATA_MODE=database`. Demo mode is synthetic in-memory data, not a fallback or proof
that PostgreSQL and workload identity work.

## 3. Compare behavior

If you completed the Python path in this PowerShell session, compare the complete
inventory response from both implementations:

```powershell
if (Get-Variable -Name pythonInventorySnapshot -ErrorAction SilentlyContinue) {
    $javaInventorySnapshot = @(
        $materials | Sort-Object lot_number |
            Select-Object id, name, category, lot_number, quantity, unit, status, location, expiry_date, image_url
    )
    $pythonJson = ConvertTo-Json -InputObject $pythonInventorySnapshot -Depth 4 -Compress
    $javaJson = ConvertTo-Json -InputObject $javaInventorySnapshot -Depth 4 -Compress
    if ($pythonJson -cne $javaJson) {
        throw 'The Python and Java inventory responses differ. Investigate before continuing.'
    }
    'Python and Java returned the same seeded inventory.'
}
else {
    'Python comparison was not run in this session; the Java database checks still apply.'
}
```

Compare the browser experience and the code paths as well. A matching sample
response does not prove that the implementations behave identically for all inputs
or failures.

## Checkpoint

The Java tests pass, both Java pods are ready, and the API and web application show
the seeded database inventory. If you ran both paths, you have compared their
responses and can identify the evidence you would need for a production migration.

[Next: operate and improve]({{ site.baseurl }}{% link appmod-lab/5-operate-and-improve/index.md %}) |
[Workshop home]({{ site.baseurl }}{% link index.md %})
