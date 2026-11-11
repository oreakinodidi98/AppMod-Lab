---
title: Module 05 - Deploy the Java application
description: Test and deploy the Java Caldova implementation against the same PostgreSQL database.
ms.topic: tutorial
nav_order: 6
---

## Goals

Build and deploy the Spring Boot implementation using the same API contract,
PostgreSQL database, and workload identity as the Python implementation. You can
complete this module after [module 03](../3-azure-environment/) without running
Python first, but the comparison is more useful if you complete both.

## 1. Inspect and test the Java implementation

Review the Java API (`Java_app/CaldovaClinicalApiJava/src/main/java/com/caldova/clinicalapi/inventory/InventoryController.java`),
its database configuration (`Java_app/CaldovaClinicalApiJava/src/main/java/com/caldova/clinicalapi/config/EntraPostgresConfiguration.java`),
and the web application (`Java_app/CaldovaClinicalWebJava/src/main/java/com/caldova/clinicalweb/inventory/InventoryPageController.java`).
These source files are not included in this checkout.
Compare their responsibilities with the Python files from module 04.

Ask Copilot to identify the shared API contract, differences in database
authentication, and tests needed before replacing one implementation with the
other. Review its answer against the code, without including tokens or customer data.

Select your JDK 17 installation. Run the existing tests from temporary copies so
Maven output is not included in the container build contexts:

```powershell
Set-Location -LiteralPath $env:LAB_REPO
$env:JAVA_HOME = Read-Host 'Full path to your JDK 17 home directory'
$env:PATH = (Join-Path $env:JAVA_HOME 'bin') + [IO.Path]::PathSeparator + $env:PATH
mvn --version

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
database-backed checks on AKS.

## 2. Select and deploy Java

```powershell
$env:LAB_API_REPOSITORY = "$($env:LAB_PREFIX)/java-api"
$env:LAB_WEB_REPOSITORY = "$($env:LAB_PREFIX)/java-web"
```

If the Python port forwards are still running, stop them with Ctrl+C. Follow the
[shared build and deployment exercise](../4-python-application/deploy-caldova/) again, then return
here. The same Kubernetes deployments are updated to the Java images, and the
existing database and identity remain in place. Reopen the port forwards for the
new pods as described in that exercise.

The Java API also has a `demo` data mode, but this exercise deliberately uses
`DATA_MODE=database`. Demo mode is synthetic in-memory data, not a fallback or proof
that PostgreSQL and workload identity work.

## 3. Compare behavior

If you completed module 04 in this PowerShell session, compare the complete
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
the seeded database inventory. If you ran both modules, you have compared their
responses and can identify the evidence you would need for a production migration.

[Next: operate and improve](../6-operate-and-improve/) |
[Workshop home](../../index.md)
