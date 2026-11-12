---
title: Agentic SDLC - Making Application Modernisation Continuous
description: Agentic SDLC - Making Application Modernisation Continuous
ms.topic: tutorial
parent: Module 02 - Automate a modernization run
nav_order: 1
---

## Goals

In this module we will focus more on Agentic SDLC and making Application Modernisation Continuous

Going from a once-a-decade rewrite to an always-on phase in the software development lifecycle (SDLC).

The idea is simple: we should not have to wait for a large migration project to keep our applications current. Modernisation can become part of how we plan, build, review, ship and operate software every day.

## 1. Agents in the SDLC

### How we got here

We have seen an evolution in tools like GitHub Copilot:

| Period | Focus | What changes |
| --- | --- | --- |
| 2021-2023 | Code completion | AI helps us write code in the editor. |
| 2024-2025 | Agentic SDLC | Agents work continuously with our development environment. |
| 2026 onwards | Hybrid teams | Agents and developers work together across the lifecycle. |

We already think about delivery as a series of phases:

**Plan -> build -> review -> ship.**

With AI, we can work across all these phases together, not just code completion. The opportunity is there to speed up delivery significantly, with measures such as **reduction in feature lead time against a baseline** showing whether it is actually helping.

### What an agentic team could look like

A good example is a set of agents with clear responsibilities across the SDLC:

1. **Orchestrator agent:** owns the end-to-end run.
2. **Spec agent:** turns intent into structured requirements.
3. **Architecture and design review agents:** an architecture agent proposes a design, while a separate design review agent, using a different model setup, independently critiques it.
4. **Implementation and code review agents:** an implementation agent writes the code, while a separate code review agent challenges it.
5. **Test agent:** generates test coverage, automating some of the work QA teams do.
6. **Continuous improvement agent:** watches every feature run and proposes updates to the team's instruction files, so the next run starts from a smarter system.
7. **Post-production agents:** a bug hunter, incident response agent, and telemetry and feedback agent keep working on the team's behalf after a change ships. Every output passes through a **human triage gate** before becoming action.

### A simple view of the flow

An engineer works in an editor or terminal and provides input in whatever form makes sense: interfaces, a spec, a document or requirements. That input feeds into the agentic SDLC.

The starting point does not always have to be the engineer, either. A user can raise feedback as an issue, triggering an automated workflow. Agents can then implement, verify and determine what needs to happen next as part of that issue. This gives the team a way to react to user feedback in real time.

[![Interactive and automated paths leading to agentic SDLC orchestration, with shared instructions, artifacts, and human gates.]({{ '/assets/images/agentic-sdlc.png' | relative_url }})]({{ '/assets/images/agentic-sdlc.png' | relative_url }})

### The work continues after production

The next image shows the post-production loop. We have a system in production, and the bug hunter, telemetry, feedback and incident response agents are actively looking for things that can or should be improved.

[![Post-production feedback loop showing agents, human triage, and approved actions feeding back into development.]({{ '/assets/images/post-production-loop.png' | relative_url }})]({{ '/assets/images/post-production-loop.png' | relative_url }})

# 2. The gap: keeping the stack current

Agents now touch every stage:

**Plan -> code -> test -> review -> secure -> operate.**

But there is still a gap: **keeping the stack current**.

We develop systems and applications, put them into production and often do not look back at the underlying stack until we have to. Agents can help close that gap.

### Modernisation the old way

Traditionally, modernisation meant a large migration project with several phases. Teams would freeze feature development to focus on dependencies, runtime versions and language upgrades.

Keeping the current system running while modernising it was complicated:

- We would find bugs, pause and fix them.
- We had to keep the current and modernised versions in sync.
- All of this took time away from delivering features.

That helps explain why companies put modernisation off:

- **Cost:** a large migration needs time, people and budget.
- **Risk:** risk drives big-bang thinking and feature freezes.
- **Scarce, temporary expertise:** the consultants or the one senior engineer who knew both stacks eventually move on.
- **Opportunity cost:** product leaders resist pausing delivery to focus on the stack.

The result is a continuous loop of technical debt. Meanwhile, the technology around us keeps evolving faster.

### Modernisation as a loop

Instead of treating it as a one-off project, we can make modernisation a repeatable agentic loop:

1. **Goal:** upgrade to Java X.
2. **Plan:** write the steps, decide the order of changes and choose the recipes to apply.
3. **Act:** edit files, run the build and execute tests.
4. **Observe:** read the signals: compile errors, failing tests and Common Vulnerabilities and Exposures (CVEs).

Repeat **plan -> act -> observe** until the outcome is reached, then open a pull request (PR) for human review.

Modernisation is mostly this loop: high-volume, tedious and machine-verifiable work. That is the sweet spot for agents.

## 3. GitHub Copilot app modernisation: end to end

This is where GitHub Copilot app modernisation fits: using the agentic SDLC to keep systems up to date.

It brings IDE plugins, multiple capabilities and models, and a knowledge base built from years of modernisation experience: how particular libraries are modernised and which steps are required.

A general-purpose agent does not have to spend all that time and those tokens rediscovering the migration path. App modernisation brings that knowledge with it.

### One workflow, end to end

| Stage | What happens |
| --- | --- |
| **Assess** | Scan code and dependencies for issues and cloud blockers. Understand the current project, produce assessment results and findings, and suggest tasks with instructions. |
| **Plan** | Draft an editable upgrade plan with step-by-step changes that you review and approve first. |
| **Upgrade** | Execute the plan, changing runtimes, frameworks and dependencies. |
| **Validate** | Run builds, tests, CVE scans and consistency checks, including checks for inconsistencies between dependencies. |
| **Migrate** | Optionally replace on-premises patterns with Azure services when moving to the cloud. |
| **Deploy** | Containerise, provision and deploy to Azure, taking the modernised code through to a running cloud application. |

### Inside the plan, upgrade and validate loop

The agent:

1. Drafts a plan that you can edit and approve.
2. Applies OpenRewrite recipes.
3. Builds the application and fixes what the recipes missed.
4. Runs tests and repairs regressions.
5. Checks CVEs and behaviour changes.
6. Commits each step and writes a summary.

The focus is not just modernised code. It is getting to a running app: **containerise -> provision -> deploy -> fix where needed**.

### Reusing what already worked

Cloud migration patterns can become reusable tasks.

We can build a task from:

- A commit that handled a migration well.
- A Markdown guide.
- A documentation URL.

Then we can replay that task on every application that needs it.

For example, take the commit where your best engineer migrated a service to your internal logging library or an approved service. Turn that into a custom task, rather than asking every team to work out the same migration again.

## 1. The starting point

For this module, you'll need the original todo app on your repository's default
branch. Choose the option that matches where you are:

* **Starting fresh:** Download the todo app into your new workshop repository.
* **Completed module 01:** Return to the default branch where you saved the
  original todo app.

First, make sure you've completed the [repository and setup instructions in
module 00]({{ site.baseurl }}{% link appmod-lab/0-prerequisites/prerequisite-0-1-technical.md %}#create-your-workshop-repository).
If you've opened a new PowerShell terminal, repeat those instructions to set
`LAB_APP_REPO` and download, verify, and review the setup script again.

### Option 1: Start fresh

Open your cloned workshop repository in PowerShell and check your branch and
working tree:

```powershell
Set-Location -LiteralPath $env:LAB_APP_REPO
git branch --show-current
git status --short
```

Confirm you're on your default branch and have no unrelated changes. Then
download the todo app:

```powershell
& $env:LAB_SETUP -Module todo
git status --short
```

Review the downloaded `src` folder, then commit and push it to your default
branch:

```powershell
git add -- src
git commit -m "Add todo application for workshop"
git push
```

If `src` already exists, the setup script will stop rather than overwrite it.
Review the existing folder before continuing.

### Option 2: Continue from module 01

Save any work on your interactive upgrade branch, then return to your default
branch. The example uses `main`; change it if your default branch has a
different name.

```powershell
Set-Location -LiteralPath $env:LAB_APP_REPO
git status --short
git switch main
```

Confirm that the switch succeeded and that this branch contains the original
`src` app you committed and pushed before the interactive upgrade. You do not
need to download it again. Your repository may also contain a README or other
files.

### What we want to change

We want to move beyond Java 8. Potential upgrade targets include **Java 11, 17 or 25**. For the walkthrough below, we use **Java 21** as a clear, consistent demo target.

We will create a **Java Continuous modernization** workflow that uses the CLI tool from GitHub Copilot app modernisation.

The workflow downloads and installs the CLI, then runs the modernisation step using the workflow input to guide the agentic workflow.

We can run it manually and provide an instruction, for example:

- Upgrade Log4j to the latest version.
- Upgrade to Spring Boot 4.
- Upgrade to a specific Java version.

These are example requests; each still needs an assessment of compatibility and validation of the resulting changes.

We will set the workflow to also have a daily schedule, so modernisation can run continuously rather than waiting for someone to start a migration project. This is a recurring modernisation run, not a guarantee of application uptime.

## 2. Prepare authentication and CI

In your repository's **Settings > Actions > General**, check that Actions are
allowed and that workflows can create pull requests.

The workflow we create will checks for two repository Actions secrets:

* `GH_TOKEN`: a GitHub personal access token authorized for the Copilot account used by Modernize CLI
* `CONTINUOUS_APPMOD_GH_TOKEN`: a token authorized to write repository contents and workflows in your workshop repository so the result branch can be pushed

Create these through **Settings > Secrets and variables > Actions** in your repository,
using your organization's approved token policy, minimum scope, and short expiry.

> Never put token values in source, a terminal transcript, a prompt, or a screenshot.

### Create a CI workflow

in this section we will use copilot to create a CI workflow to make sure the app in `src`  builds successfully with Java 8.

Run or show **Build and test** passing on `main`

run the following prmpty to create your yml

```txt
Create a GitHub Actions workflow at .github/workflows/ci.yml to build and
test the todo app in the src folder.

Name it "Build and test". It should:

- Run on pushes and pull requests targeting main when files under src/ change.
- Also allow manual runs with workflow_dispatch.
- Grant only contents: read permission.
- Cancel an older run when a newer run starts for the same branch or pull request.
- Run on ubuntu-latest with a 15-minute timeout.
- Check out the code using actions/checkout@v4.
- Read java.version from src/pom.xml, convert 1.8 to 8, and use 8 if
  the property is missing. Expose the result as a step output.
- Install that version of Temurin using actions/setup-java@v4 and cache
  Maven dependencies using src/pom.xml.
- Run mvn --batch-mode --no-transfer-progress verify from the src folder.

Add short comments explaining the main steps. Show me the workflow and
explain it before I review and commit it.
```

if after running the prompt yaml result the file still doesnt work and youve troubleshooted it you can use the following workflow

```yml
name: Build and test

on:
  push:
    branches: [main]
    paths:
      - 'src/**'
  pull_request:
    branches: [main]
    paths:
      - 'src/**'
  workflow_dispatch:

permissions:
  contents: read
# If a newer CI run starts for the same branch or PR, the older in-progress run is cancelled
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build:
    name: Build and test
    runs-on: ubuntu-latest
    timeout-minutes: 15

    steps:
# Checks out the source code
      - name: Check out source
        uses: actions/checkout@v4
# Reads java.version from src/pom.xml (1.8 -> 8) so CI matches the Java version of the branch being built, including modernised branches
      - name: Detect Java version from pom.xml
        id: java
        run: |
          version=$(sed -n 's:.*<java.version>\(.*\)</java.version>.*:\1:p' src/pom.xml | head -n1)
          version="${version#1.}"
          echo "version=${version:-8}" >> "$GITHUB_OUTPUT"
          echo "Using Java ${version:-8}"
# Install the Temurin JDK detected from the pom
      - name: Set up Temurin ${{ steps.java.outputs.version }}
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: ${{ steps.java.outputs.version }}
          cache: maven
          cache-dependency-path: src/pom.xml
# Maven command to compile the app, run tests, and perform any configured verification checks
      - name: Build and test
        working-directory: src
        run: mvn --batch-mode --no-transfer-progress verify
```

Manually run **Build and test** on the repository's default branch and inspect its
result. Both workflows are manual; the modernization workflow dispatches CI for
its result branch. The modernization
workflow configures its own JDKs; the separate Copilot setup workflow is not a
prerequisite for its CLI job.

## 3. Start the run

1. In your repository, open **Actions > Java Continuous modernization**.
2. Select **Run workflow** on the default branch and enter your agreed, supported upgrade target.
3. Follow the run through CLI installation, upgrade, result-branch creation, pull-request creation, and CI dispatch.

The workflow checks out the repository's **default branch**, regardless of the interactive
branch used in module 01. It runs the CLI with `--no-tty`; there is no human
approval of the generated plan before execution. Human review happens at the
resulting pull request. The workflow does not merge it.

## 4. Review the result

Open the workflow summary and, if a change was produced, open its pull request:

* Check the target, changed files, generated reports, and any unresolved findings.
* Confirm that **Build and test** ran on the result branch and inspect its actual result.
* If you completed module 01, compare the result with its baseline and interactive plan.
* Decide what further testing and human approvals are required before a real merge.

If the CLI produces no net change, the workflow reports that outcome and creates no
result branch or pull request. If pull-request creation fails after a branch was
pushed, the workflow summary points to the branch; investigate before proceeding.
Inspect the uploaded logs and recovery bundle when available, and treat their contents
as potentially sensitive.

Disable **Java Continuous modernization** when finished. Remove the demonstration
secrets or revoke the short-lived tokens when they are no longer needed.

## Checkpoint

You can explain the actual automation trigger, source branch, plan-approval
limitation, CI result, and human review gate. A failed or skipped run is a learning
result to investigate, not a successful modernization.

[Next: create the Azure environment]({{ site.baseurl }}{% link appmod-lab/3-azure-environment/index.md %}) |
[Workshop home]({{ site.baseurl }}{% link index.md %})
