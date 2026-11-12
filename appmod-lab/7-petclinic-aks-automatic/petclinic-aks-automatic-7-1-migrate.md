---
title: Assess and migrate PetClinic
description: Assess Spring PetClinic, review a passwordless PostgreSQL migration, and validate an AKS Automatic deployment.
ms.topic: tutorial
parent: Module 07 - Modernize PetClinic for AKS Automatic
nav_order: 1
---

## Goals

Run Spring PetClinic with PostgreSQL, assess it with GitHub Copilot modernization,
and implement a reviewed migration to AKS Automatic with Microsoft Entra Workload
ID. This module uses the public Spring PetClinic app, not the todo app
from module 01 or either Caldova implementation. The assessment screenshots are
in this lab's `assets/images` folder.

Allow 120-150 minutes, plus time to create the Azure environment. The screenshots show one
extension version and source revision; labels, issue counts, and effort estimates
can differ. The app is for synthetic veterinary records only.

## 1. Prepare the environment

Complete [module 00]({% link appmod-lab/0-prerequisites/index.md %}). You also need Docker Desktop with
Linux containers, Docker Compose, the Java Extension Pack, and the
[GitHub Copilot modernization extension](https://marketplace.visualstudio.com/items?itemName=vscjava.migrate-java-to-azure).
Use your own licensed GitHub account and approved Azure subscription. There is no
preconfigured VM, shared account, or Resources tab provided by this repository.

Agree with your facilitator on a PetClinic source revision and compatible JDK
before the session. Upstream requirements change; Java 17 is not guaranteed to
build the current default branch. Record the selected commit and inspect its
Maven Java requirement rather than assuming it matches a screenshot.

The [modernization tools](https://learn.microsoft.com/azure/developer/java/migration/migrate-github-copilot-app-modernization-for-java-quickstart-assess-migrate)
currently require Java 21 or later. This is separate from the JDK used to build
your chosen PetClinic version. Check both before the session.

From PowerShell 7.4 or later, choose a separate parent directory outside this repo:

```powershell
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$parent = Read-Host 'Existing directory for the separate PetClinic checkout'
Set-Location -LiteralPath $parent
git clone https://github.com/spring-projects/spring-petclinic.git
Set-Location spring-petclinic
$sourceRef = Read-Host 'Facilitator-approved PetClinic tag or commit'
git switch --detach $sourceRef
git rev-parse HEAD
git switch -c petclinic-aks-modernization
java -version
.\mvnw.cmd --version
code .
```

Review the selected checkout's README, Maven configuration, PostgreSQL profile,
and Compose file. Sign in to Copilot in the new VS Code window. Select a model
permitted by your organization; a particular model is not required.

For deployment, use [module 03]({% link appmod-lab/3-azure-environment/index.md %})
to create a dedicated environment, or agree on an equivalent with your facilitator.
You can reuse the lab cluster, registry, and PostgreSQL server, but PetClinic
needs its own database, namespace, and reviewed identity setup. Do not import its
schema into Caldova's database or reuse Caldova's read-only grants: PetClinic
also writes records.

In the terminal with your module 03 lab settings, generate PetClinic's separate
names using the same values:

```powershell
. (Join-Path $env:LAB_APP_REPO 'assets\scripts\lab-names.ps1')
$petclinicNames = Get-LabResourceNames -Application $env:LAB_APPLICATION -Environment $env:LAB_ENVIRONMENT `
    -RegionCode $env:LAB_REGION_CODE -Owner $env:LAB_OWNER -Instance $env:LAB_INSTANCE -Location $env:LAB_LOCATION
$petclinicNames | Select-Object PetClinicDatabase, PetClinicNamespace, PetClinicIdentity, `
    PetClinicServiceAccount, PetClinicFederation, PetClinicApp, PetClinicConfig
```

Use these names in the approved plan and generated deployment files. Use
`PetClinicApp` for both the deployment and service, and `PetClinicConfig` for the
ConfigMap. The `dbpc`, `nspc`, `idpc`, `sapc`, and `ficpc` prefixes keep PetClinic separate from Caldova
without changing the agreed application, environment, region, owner, or instance.
If you opened a new terminal, restore the module 03 settings from your private
notes first.

> [!WARNING]
> Azure resources and image builds incur charges. You do not need to grant
> yourself Cluster Admin for this exercise. Ask the platform owner
> for the least privilege needed for your namespace and approved identity setup.
> Do not run copied setup, cleanup, or Service Connector commands without
> checking which resources and permissions they change.

## 2. Run PetClinic locally with PostgreSQL

Confirm the selected checkout defines a Compose service named `postgres` and
check its port mapping and local development credentials before starting it:

```powershell
docker version
docker compose config --services
docker compose up -d postgres
docker compose ps
```

Wait for the database to be ready according to the Compose health check or
PostgreSQL readiness output. If port 5432 is occupied by Caldova or another
database, choose a different host port in your local Compose configuration and
match it in the datasource URL. Do not stop unrelated services.

Set the connection values to match your local Compose settings. The following
uses the local `postgres` Spring profile; check that it exists in your revision:

```powershell
$env:SPRING_DATASOURCE_URL = Read-Host 'Local JDBC URL, for example jdbc:postgresql://localhost:5432/petclinic'
$env:SPRING_DATASOURCE_USERNAME = Read-Host 'Local Compose database username'
$env:SPRING_DATASOURCE_PASSWORD = Read-Host 'Local Compose database password' -MaskInput
.\mvnw.cmd --batch-mode --no-transfer-progress verify
.\mvnw.cmd spring-boot:run '-Dspring-boot.run.profiles=postgres'
```

Use the initialization procedure in the selected upstream README if its
PostgreSQL profile needs additional setup. Any schema or seed initialization is
for this disposable local database only, never a customer or migrated database.

Open <http://localhost:8080> and record how the app works before making changes:

1. Find owners with an empty last-name search and open an owner's details.
2. Edit a synthetic pet record, then reload to verify persistence.
3. Open Veterinarians and review the displayed specialties.
4. Record the Maven verification result and any pre-existing failures.

Do not expect a fixed count of owners or veterinarians across source revisions.
Basic authentication is not assumed; record any authentication configured in
your selected revision. Stop the application with Ctrl+C.

## 3. Configure and run the assessment

Open **GitHub Copilot modernization** in the activity bar.

![Modernization activity-bar entry]({{ '/assets/images/GitHub_Copilot_modernization_extension.png' | relative_url }})

The quickstart panel offers assessment, runtime upgrades, Azure migration, and
security work. Select **Start Assessment** to review assessment settings first.
Some versions enter assessment through **Migrate to Azure**.

![Modernization quickstart actions]({{ '/assets/images/quickstart.png' | relative_url }})

Choose **Custom Assessment** when you need explicit control over scope.

![Recommended and custom assessment]({{ '/assets/images/custom.png' | relative_url }})

Use these settings for the lab:

| Setting | Choice and reason |
| --- | --- |
| Assessment domains | Cloud Readiness; add Java Upgrade only for an agreed runtime change |
| Analysis coverage | Issue only for a quick first pass; Full analysis for architecture and related insights |
| Target runtime | A supported JDK compatible with the approved framework target |
| Target compute service | Azure Kubernetes Service (AKS) |
| Target operating system | Linux for this deployment |
| Containerization | Enable to include containerization findings |
| Security | Optional additional scope, with time reserved to review findings |

![Example assessment configuration]({{ '/assets/images/customassessment.png' | relative_url }})

The screenshot includes multiple compute targets and operating systems; narrow
them to the choices above instead of accepting every selected default. Allow the
extension to install its assessment prerequisites when approved. Follow progress
in Copilot Chat and the extension's output channel.

**Checkpoint:** Record the source commit, assessment configuration, report
location, and whether the assessment succeeded. If it failed, fix the problem
before treating the report as complete.

## 4. Interpret the report and select a migration

![Example assessment report]({{ '/assets/images/Assessment_Results.png' | relative_url }})

Select **Azure Kubernetes Service (AKS)** in the report's target selector. Inspect
the Issues tab and, when generated by full analysis, Architecture, API Contracts,
Configuration, Business Workflows, Dependencies, and Data Model.

The sample shows 9 cloud-readiness issues and 2 upgrade issues. Your results may
differ. Record what your assessment found; the story points are estimates, not
measured delivery time. Review Mandatory findings first. Check whether Potential
findings apply to your app, then agree which Optional improvements to include.
Review each proposed change rather than relying on its label.

Choose the PostgreSQL passwordless migration recommendation when available:

| Review question | Evidence to collect |
| --- | --- |
| What was found? | The source location and current PostgreSQL connection configuration |
| Why change it? | Local credentials and connectivity assumptions do not establish AKS identity access |
| Proposed solution | Entra-aware database connection code, TLS, token renewal, and scoped database permissions |
| Behavior to preserve | Owner search, pet edits, veterinarian views, and stored records |
| Proof required | Maven verification plus database-backed behavior from the deployed pod |

Use **Run Task** for a guided migration if offered, or **Ask Copilot** for a
reviewable custom plan. If the selected revision has no matching finding, inspect
the configuration and discuss the gap; do not manufacture a vulnerability.

```text
Plan a migration of this PetClinic checkout to our approved AKS Automatic
environment and a dedicated Azure PostgreSQL database using Entra Workload ID.
Use the PetClinic names displayed by the shared naming helper. Apply our agreed
application, environment, region, owner, and instance tags to new Azure resources.
Preserve owner, pet, visit, and veterinarian behavior. Include token renewal,
TLS verification, least-privilege database grants, data transfer and validation,
containerization, probes, functional tests, and rollback. Do not modify Azure
resources or code until I approve the plan.
```

## 5. Make and test the approved changes

Approve a small set of changes, then review the diff and rerun
`.\mvnw.cmd --batch-mode --no-transfer-progress verify` with the selected JDK.
Repeat the local checks from step 2. Do not combine a framework upgrade with the
database migration unless both were explicitly approved.

Ask Copilot to generate a non-root Dockerfile and namespace-scoped deployment
artifacts using the actual application port, configuration, and health endpoints.
Review build contexts, resource requests/limits, probes, and immutable image
references. If you use Containerization Assist MCP, install only an approved
server and review its requested tools and actions; it is optional for this lab.

Workload ID requires a service account, pod label, federated credential, and
application support for token-based connections. An Entra administrator must also
create the database principal and required grants. A new namespace and service
account need a matching federation subject; the one from module 03 is for Caldova.
See the
[Workload ID overview](https://learn.microsoft.com/azure/aks/workload-identity-overview).
Service Connector can automate parts of setup, but does not replace review of
application code or prove data migration. Use the
[Service Connector overview](https://learn.microsoft.com/azure/service-connector/overview)
to evaluate it with your platform owner before authorizing any changes.

Agree on whether to transfer local synthetic records or initialize a fresh demo
database. For a transfer, stop writes, use the PostgreSQL tools compatible with
both servers, and review schema, ownership, grants, row counts, and application
reads afterward. Keep dumps private. Disable destructive startup schema/seed
initialization for the migrated database and preserve a rollback copy.

## 6. Deploy and validate on AKS Automatic

Confirm the subscription, cluster context, namespace permissions, database
network path, registry pull access, and federation subject. Build in ACR and
record an immutable image digest using the approach in the
[deployment exercise]({% link appmod-lab/4-deploy-application/deploy-caldova.md %}),
but use only its build and digest approach, adapted for PetClinic's single app
image. Do not run its two-image build commands unchanged or use its Caldova-specific
manifests, environment variables, or schema. Review a server-side dry run of
your generated PetClinic manifests before approving deployment.

In the terminal configured for your approved cluster, adapt these inputs to the
generated resources:

```powershell
$namespace = Read-Host 'Approved PetClinic namespace'
$deployment = Read-Host 'PetClinic deployment name'
$service = Read-Host 'PetClinic service name'
$servicePort = Read-Host 'PetClinic service port'
kubectl config current-context
kubectl rollout status "deployment/$deployment" --namespace $namespace --timeout=10m
kubectl get pods,services --namespace $namespace
kubectl get events --namespace $namespace --sort-by=.lastTimestamp
kubectl port-forward --namespace $namespace "service/$service" "8080:$servicePort"
```

Open <http://localhost:8080>. Repeat the baseline checks, verify the expected
records in Azure PostgreSQL, and confirm edits survive a pod replacement. Confirm
that the deployed configuration uses Entra authentication without a database
password. Review readiness and logs without exposing tokens or connection secrets.

**Checkpoint:** Keep the source commit, report, approved plan, code diff, test
results, image digest, and the results of your database and browser checks.
An assessment report or a healthy pod alone does not prove a successful migration.

## Troubleshooting and cleanup

If Maven reports an unsupported Java release, compare its selected JDK with the
checkout's build requirements. If port 8080 is occupied, stop only your previous
lab process or choose another local application/forwarding port. For database
failures, check TLS, network access, principal grants, and identity configuration
before changing application behavior or widening firewall rules.

Stop the port forward with Ctrl+C. In the PetClinic checkout, run
`docker compose down` to stop the local database; this retains named volumes.
Remove password environment variables from the application terminal. Delete only
your lab's database volumes or private dumps once they are no longer needed.

For resources created through module 03, follow [module 08]({% link appmod-lab/8-cleanup/index.md %}) after
all exercises sharing the environment are finished. For a facilitator-owned
environment, hand the owner an inventory of PetClinic resources, grants, and
connections to remove; do not delete the shared resource group.

[Next: clean up]({% link appmod-lab/8-cleanup/index.md %}) | [Workshop home]({% link index.md %})