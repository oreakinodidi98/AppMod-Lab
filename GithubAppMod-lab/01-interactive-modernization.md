---
title: Module 01 - Modernize Java interactively
description: Establish a Java baseline and review an interactive GitHub Copilot modernization plan.
ms.topic: tutorial
---

## Goals

Run the existing todo application, identify what must remain true, and use an
interactive modernization plan to make a bounded change. This module uses the
separate [`src`](../src/) application, not the Java version of Caldova.

![Interactive and automated inputs to an agent-assisted delivery flow](../Agentic_SDLC/images/image.png)

The image presents an intended operating model. In this repository, the automated
workflow in the next module does not have the same plan-approval gate as the
interactive path.

## 1. Establish the baseline

The current [`pom.xml`](../src/pom.xml) declares Java 8 and Spring Boot 2.7.18.
The application is a server-rendered todo list using an embedded H2 database.

From your repository root, select your installed JDK 8 directory and run the same
Maven verification used by the repository's build workflow:

```powershell
Set-Location -LiteralPath $env:LAB_REPO
$env:JAVA_HOME = Read-Host 'Full path to your JDK 8 home directory'
if (-not (Test-Path (Join-Path $env:JAVA_HOME 'bin\java.exe')) -and $IsWindows) {
    throw 'The JDK 8 directory does not contain bin\java.exe.'
}
$env:PATH = (Join-Path $env:JAVA_HOME 'bin') + [IO.Path]::PathSeparator + $env:PATH
java -version
mvn --version
mvn --file (Join-Path $env:LAB_REPO 'src\pom.xml') --batch-mode --no-transfer-progress verify
if ($LASTEXITCODE -ne 0) { throw 'Baseline verification failed. Investigate before upgrading.' }
```

Confirm that Maven reports Java 8 and that verification succeeds. Record any
pre-existing failure rather than attributing it to the upgrade.

Run the application on a free local port:

```powershell
$todoPort = Read-Host 'Free local port for the todo application'
mvn --file (Join-Path $env:LAB_REPO 'src\pom.xml') spring-boot:run "-Dspring-boot.run.arguments=--server.port=$todoPort"
```

Open `http://127.0.0.1:<your-port>` in a browser. Create a todo, mark it complete,
and delete it. Stop the application with Ctrl+C. The embedded database is for the
sample; do not enter customer data.

## 2. Create an isolated upgrade branch

Check that your working tree is clean, then choose a new branch name:

```powershell
git status --short
$upgradeBranch = Read-Host 'New branch name for the interactive upgrade'
git switch -c $upgradeBranch
if ($LASTEXITCODE -ne 0) { throw 'Could not create the upgrade branch.' }
```

Keep the fork's default branch unchanged. The automated workflow later starts from
that default branch, not from this interactive branch.

## 3. Assess and approve a plan

1. Open the repository in Visual Studio Code and sign in to GitHub Copilot.
2. In the GitHub Copilot modernization panel, select **Upgrade Java Runtime & Frameworks**, or request a Java upgrade in Copilot Chat agent mode.
3. Select a supported target JDK and, if needed, a compatible framework target. Choose them with the customer; do not assume that the newest version is compatible.
4. Review the generated plan before approving execution. Check dependencies, behavior to preserve, test commands, security findings, and rollback.

For example, adapt this prompt to your agreed target:

```text
Assess the todo application in src for an upgrade to my chosen supported Java
and framework versions. Preserve the existing todo behavior. Show the proposed
steps, compatibility risks, required JDKs, tests, and rollback approach. Wait
for my approval before making changes.
```

Approve only the agreed scope. Follow the
[interactive modernization quickstart](https://learn.microsoft.com/azure/developer/github-copilot-app-modernization/quickstart-upgrade)
if the extension presents different options.

## 4. Validate and review

After the agent finishes, read its summary and inspect the actual diff:

```powershell
git status --short
git --no-pager diff
```

If the agent created commits, also inspect those commits relative to the fork's
default branch. Select the target JDK in your shell and rerun the `mvn ... verify`
command from step 1. Run the application again and repeat the create, complete, and
delete checks. Record the exact target, commands, results, unresolved findings, and
any behavior you could not verify.

Do not merge the branch as part of this exercise. A successful build or an agent
summary is evidence for review, not approval to ship.

## Checkpoint

You have a recorded baseline, an explicitly approved target and plan, a reviewable
change, and test and behavior results. If the upgrade did not complete, identify
the blocker and retain the evidence instead of reporting success.

[Next: automated modernization](./02-automated-modernization.md) |
[Workshop home](./README.md)
