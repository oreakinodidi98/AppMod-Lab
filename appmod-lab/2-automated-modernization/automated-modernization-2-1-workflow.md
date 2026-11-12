---
title: Agentic SDLC - Making Application Modernisation Continuous
description: Agentic SDLC - Making Application Modernisation Continuous
ms.topic: tutorial
parent: Module 02 - Automate a modernization run
nav_order: 1
---

## Goals

In this module, we'll explore the agentic software development lifecycle (SDLC) and how we can make application modernisation continuous.

We'll look at how teams can move from a once-a-decade rewrite to an ongoing part of software delivery, then prepare the todo app for an automated modernisation run.

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

## 2. The gap: keeping the stack current

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

These are the stages an interactive modernisation can cover. In an automated
run, the review point can be different: the workflow may make changes before a
person reviews the resulting pull request.

| Stage | What happens |
| --- | --- |
| **Assess** | Scan code and dependencies for issues and cloud blockers. Understand the current project, produce assessment results and findings, and suggest tasks with instructions. |
| **Plan** | Draft an editable upgrade plan with step-by-step changes that you review and approve first. |
| **Upgrade** | Execute the plan, changing runtimes, frameworks and dependencies. |
| **Validate** | Run builds, tests, CVE scans and consistency checks, including checks for inconsistencies between dependencies. |
| **Migrate** | Optionally replace on-premises patterns with Azure services when moving to the cloud. |
| **Deploy** | Containerise, provision and deploy to Azure, taking the modernised code through to a running cloud application. |

### Inside the plan, upgrade and validate loop

In an interactive upgrade, the agent can:

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

## 4. The starting point

Now let's move from the concept to the workshop. We'll start with the original
todo app and prepare a build workflow that can validate it.

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

The next part of the exercise is intended to create a **Java Continuous modernization**
workflow that uses the CLI tool from GitHub Copilot app modernisation.

The workflow downloads and installs the CLI, then runs the modernisation step using the workflow input to guide the agentic workflow.

We can run it manually and provide an instruction, for example:

- Upgrade Log4j to the latest version.
- Upgrade to Spring Boot 4.
- Upgrade to a specific Java version.

These are example modernisation goals, not guaranteed workflow inputs. Check what
the CLI and workflow accept; each goal still needs a compatibility assessment
and validation of the resulting changes.

The intended workflow also has a daily schedule, so modernisation can run
regularly rather than waiting for someone to start a migration project. This is
a recurring modernisation run, not a guarantee of application uptime. Review
and approve any scheduled runs and their costs before enabling them.

## 5. Prepare authentication and CI

First, prepare access for the intended modernisation workflow. Then create and
run a separate CI workflow to establish a build and test baseline.

In your repository's **Settings > Actions > General**, check that Actions are
allowed and that workflows can create pull requests.

The example modernisation workflow uses two repository Actions secrets:

* `GH_TOKEN`: a GitHub personal access token authorized for the Copilot account used by Modernize CLI
* `CONTINUOUS_APPMOD_GH_TOKEN`: a token authorized to write repository contents and workflows in your workshop repository so the result branch can be pushed

Create these through **Settings > Secrets and variables > Actions** in your repository,
using your organization's approved token policy, minimum scope, and short expiry.

> Never put token values in source, a terminal transcript, a prompt, or a screenshot.

### Create a CI workflow

We'll use Copilot to create a CI workflow that builds and tests the app in `src`.
It reads the Java version from the app's `pom.xml`, so the baseline uses Java 8
and later runs can use the version in the branch being tested.

Enter the following prompt in Copilot Chat:

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

Review Copilot's output and save it as `.github/workflows/ci.yml`. Check the
triggers, permissions, Java version detection, and Maven command before
committing it. If your default branch is not `main`, update the branch filters
to match.

From the repository root, commit and push the workflow:

```powershell
git add -- .github/workflows/ci.yml
git commit -m "Add build and test workflow"
git push
```

In GitHub, open **Actions > Build and test**, select **Run workflow**, and
choose your default branch. Wait for the run to finish and check that the build
and tests pass. If they fail, inspect the logs and troubleshoot before
continuing. Remove any secrets from errors before sharing them with Copilot.

If you're still having trouble with the generated workflow after
troubleshooting, you can use the following example for `.github/workflows/ci.yml`.
Adjust the branch filters if needed, review the file, commit and push the
change, then run **Build and test** again.

{% raw %}
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
{% endraw %}

The example CI workflow also runs on pushes and pull requests targeting `main`
when files under `src` change. A modernization workflow can dispatch it
separately for a result branch if that workflow is configured to do so. The
example modernisation workflow configures its own JDKs; its CLI job does not
need a separate Copilot setup workflow.

## 6. Set up the Copilot environment

Next, we'll prepare the environment for Copilot cloud agent sessions that run
on GitHub Actions. This workflow installs the JDKs and checks the Maven setup,
with Java 8 as the default for the original app.

This is separate from the Modernize CLI workflow: it does not configure the
CLI job or run the modernization. It also does not apply to Copilot sessions
running in a cloud sandbox or locally in VS Code.

1. In VS Code, open your workshop repository and expand `.github/workflows`.
2. Create a file named `copilot-setup-steps.yml`. If it already exists, review
   it before making changes instead of overwriting it.
3. Copy the following YAML into the file and save it. If your default branch
   is not `main`, change the `push` branch filter to your default branch.

```yaml
name: Copilot Setup Steps

on:
  workflow_dispatch:
  push:
    branches:
      - main
    paths:
      - .github/workflows/copilot-setup-steps.yml
  pull_request:
    paths:
      - .github/workflows/copilot-setup-steps.yml
# This workflow configures the Copilot cloud agent environment for sessions running on GitHub Actions.
# Prepares and validates Copilot’s Java development environment so the agent can work on a Java 8 project while still having newer JDKs available for modernization tasks.
jobs:
# Job must be named copilot-setup-steps so GitHub Copilot recognizes it.
  copilot-setup-steps:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    permissions:
      contents: read
    steps:
# Pulls the repo code into the runner so setup validation can inspect files and tooling
      - name: Checkout repository
        uses: actions/checkout@v6
# Installs Java 11, 17, 21, 25, and 8, and configures Maven toolchains for them.
# Because Java 8 is listed last, it becomes the default JAVA_HOME and PATH Java executables.
      - name: Install JDKs and configure Maven toolchains
        uses: actions/setup-java@v5
        with:
          distribution: temurin
          # The last JDK becomes the default for JAVA_HOME and PATH.
          java-version: |
            11
            17
            21
            25
            8
          overwrite-settings: false
# Confirms the runner has Maven 3
      - name: Verify runner-provided Maven 3
        shell: bash
        run: |
          mvn --version | tee "$RUNNER_TEMP/maven-version.txt"
          grep -Eq '^Apache Maven 3\.' "$RUNNER_TEMP/maven-version.txt"
# Python script to check that Maven’s ~/.m2/toolchains.xml contains exactly one Temurin toolchain for each required JDK version: 8, 11, 17, 21, and 25.
# Then Verifies Java 8 is the default
      - name: Verify JDKs and Maven toolchains
        shell: python
        run: |
          import os
          from pathlib import Path
          import re
          import shutil
          import subprocess
          import xml.etree.ElementTree as ET

          root = ET.parse(Path.home() / ".m2" / "toolchains.xml").getroot()
          for version in ("8", "11", "17", "21", "25"):
              entries = [
                  entry for entry in root.findall("{*}toolchain")
                  if entry.findtext("{*}type") == "jdk"
                  and entry.findtext("{*}provides/{*}id") == "temurin_" + version
              ]
              if len(entries) != 1:
                  raise RuntimeError("Expected one Temurin toolchain for JDK " + version)
              entry = entries[0]
              if entry.findtext("{*}provides/{*}version") != version:
                  raise RuntimeError("Incorrect toolchain version for JDK " + version)
              home = Path(entry.findtext("{*}configuration/{*}jdkHome"))
              for tool in ("java", "javac"):
                  result = subprocess.run(
                      [str(home / "bin" / tool), "-version"],
                      check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                      text=True,
                  )
                  print(result.stdout, end="")
                  match = re.search(r'(?:version\s+"|javac\s+)(?:1\.)?(\d+)', result.stdout)
                  if not match or match.group(1) != version:
                      raise RuntimeError("Incorrect " + tool + " version for JDK " + version)
              if version == "8":
                  if Path(os.environ["JAVA_HOME"]).resolve() != home.resolve():
                      raise RuntimeError("JAVA_HOME must default to JDK 8")
                  for tool in ("java", "javac"):
                      if Path(shutil.which(tool)).resolve() != (home / "bin" / tool).resolve():
                          raise RuntimeError(tool + " on PATH must default to JDK 8")
```

Review the file, confirm you're on your default branch, then commit and push it
from the repository root:

```powershell
git add -- .github/workflows/copilot-setup-steps.yml
git commit -m "Add Copilot setup steps"
git push
```

In GitHub, open **Actions > Copilot Setup Steps** and check the run triggered by
the push. You can also select **Run workflow** on the default branch. Confirm
that the Maven and JDK checks pass before continuing. If they fail, inspect the
logs and troubleshoot; remove any sensitive information before sharing errors.
If setup fails during a Copilot session, Copilot may still begin work with an
incomplete environment, so check the session logs as well.

The file must be on the default branch for Copilot to use it. See
[Configure the development environment for agents on GitHub Actions](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/customize-the-agent-environment)
for details.

## 7. Start the run

> **Before continuing:** The steps to create the **Java Continuous modernization**
> workflow have not yet been added to this module. The steps below describe the
> intended example; wait until that workflow is available in your repository,
> then review its triggers and behaviour before running it.

1. In your repository, open **Actions > Java Continuous modernization**.
2. Select **Run workflow** on the default branch and enter your agreed, supported upgrade target.
3. Follow the run through CLI installation, upgrade, result-branch creation, pull-request creation, and CI dispatch.

The example workflow checks out the repository's **default branch**, regardless
of the interactive branch used in module 01. It runs the CLI with `--no-tty`; there is no human
approval of the generated plan before execution. Human review happens at the
resulting pull request. The workflow does not merge it.

## 8. Review the result

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
