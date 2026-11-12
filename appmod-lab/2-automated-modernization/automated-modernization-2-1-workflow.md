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

## 7. Create the continuous modernisation workflow

Now we'll add the workflow that runs Modernize CLI, creates a result branch and
pull request when there are changes, and requests a CI run for that branch.
Make sure **Build and test** passed in step 5 and that the required secrets and
permissions are in place.

> **Before you commit:** This example runs manually, on pushes that change `src`
> on `main`, and daily at 12:00 UTC. Push and scheduled runs use the CLI's
> `latest` default, not the Java 21 value you enter for a manual run. These runs
> can create branches and pull requests and consume Actions minutes. Review the
> triggers, costs, and permissions with your facilitator before enabling them.
> If automatic runs aren't approved, remove the `push` and `schedule` sections
> before committing so the workshop runs only when started manually.

Choose either option below. Both use the same reference workflow.

### Option 1: Copy the workflow

In VS Code, create `.github/workflows/modernise.yml` in your workshop repository.
Copy the reference YAML below into the file and save it. If the file already
exists, review it before making changes instead of overwriting it.

### Option 2: Use Copilot

Enter this prompt in Copilot Chat, then paste the reference YAML below it:

```text
Create .github/workflows/modernise.yml using the reference workflow I provide.
Keep its triggers, permissions, action versions, CLI commands, result branch,
pull request, CI dispatch, and recovery steps. Explain what it does and point
out any risks or assumptions before making changes. Do not commit or run it.

Reference workflow:
```

Review the generated file against the reference. Copilot may produce different
YAML, so check the commands, permissions, and triggers before continuing. You
can also copy the reference directly if you prefer.

### Reference workflow

If your default branch is not `main`, change the `push` branch filter to your
default branch. For manual-only use, remove the automatic triggers as described
above. Otherwise, copy the example as shown:

{% raw %}
```yaml
name: Java Continuous modernization

on:
  workflow_dispatch:
    inputs:
      upgrade_target:
        description: 'Upgrade target (e.g., Java 21); latest uses CLI defaults'
        required: false
        default: latest
        type: string
  push:
    branches: [main]
    paths:
      - 'src/**'
  schedule:
    - cron: '0 12 * * *'

permissions:
  contents: read
  pull-requests: write
  actions: write
# concurrency settings for the workflow, Only one run in the continuous-modernization group is coordinated at a time. Since cancel-in-progress is false, a newer run will not cancel an older one
concurrency:
  group: continuous-modernization
  cancel-in-progress: false

jobs:
# Runs on an Ubuntu GitHub-hosted runner and fails if it takes longer than 60 minutes.
  modernization:
    runs-on: ubuntu-latest
    timeout-minutes: 60
    defaults:
      run:
        shell: bash
    env:
# Stores the requested Java upgrade target. Manual runs can override it; scheduled runs use latest
      UPGRADE_TARGET: ${{ inputs.upgrade_target || 'latest' }}

    steps:
# Checks that the two secrets exist
      - name: Check authentication prerequisite
        env:
          GH_TOKEN: ${{ secrets.GH_TOKEN }}
          PUSH_TOKEN: ${{ secrets.CONTINUOUS_APPMOD_GH_TOKEN }}
        run: |
          if [ -z "$GH_TOKEN" ]; then
            echo "::error::Add a repository Actions secret named GH_TOKEN with a PAT authorized for GitHub Copilot."
            exit 1
          fi
          if [ -z "$PUSH_TOKEN" ]; then
            echo "::error::Add CONTINUOUS_APPMOD_GH_TOKEN with repository Contents and Workflows read/write permissions."
            exit 1
          fi
# Checks out the repository’s default branch with full history.
# fetch-depth: 0 gives full Git history.
# persist-credentials: false prevents the default checkout token from being saved in Git config, because the workflow later uses the custom PAT for pushing.
      - name: Check out default branch
        uses: actions/checkout@v6
        with:
          ref: ${{ github.event.repository.default_branch }}
          fetch-depth: 0
          persist-credentials: false
# Stores the starting commit SHA as steps.baseline.outputs.sha.
# This is later used to identify exactly what changed after the Modernize CLI runs.
      - name: Record starting revision
        id: baseline
        run: echo "sha=$(git rev-parse HEAD)" >> "$GITHUB_OUTPUT"
# Install multiple Java versions.
# Giving the Modernize CLI and project build tooling access to several Java versions, useful when upgrading from older Java versions or testing compatibility.
      - name: Install JDKs and configure Maven toolchains
        uses: actions/setup-java@v5
        with:
          distribution: temurin
          java-version: |
            11
            17
            21
            25
            8
          overwrite-settings: false
# Downloads and runs the Modernize CLI installer
      - name: Download Modernize CLI
        run: |
          curl -fsSL https://raw.githubusercontent.com/microsoft/modernize-cli/main/scripts/install.sh \
            -o "$RUNNER_TEMP/install-modernize.sh"
          sh "$RUNNER_TEMP/install-modernize.sh"
          echo "$HOME/.local/bin" >> "$GITHUB_PATH"
# Runs the actual modernization using the Modernize CLI, if a specific target was supplied it will upgrade to that version, otherwise it will upgrade to the latest version.
      - name: Run Modernize CLI
        env:
          GH_TOKEN: ${{ secrets.GH_TOKEN }}
        run: |
          if [ "$UPGRADE_TARGET" = "latest" ]; then
            modernize upgrade --source src --no-tty
          else
            modernize upgrade "$UPGRADE_TARGET" --source src --no-tty
          fi
# configures Git, squashes all Modernize CLI changes since the starting commit into one commit, excludes workflow changes except ci.yml, then pushes the result to a new modernization branch if anything changed.
      - name: Push changes to result branch
        id: push_changes
        env:
          BASE_SHA: ${{ steps.baseline.outputs.sha }}
          GH_TOKEN: ${{ secrets.CONTINUOUS_APPMOD_GH_TOKEN }}
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

          # Retain CLI commits for the recovery bundle before squashing the result.
          git branch "modernize-cli-backup-${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT}" HEAD
          git add -A -- .
          git reset --soft "$BASE_SHA"
          git restore --source="$BASE_SHA" --staged --worktree -- \
            .github/workflows ':(exclude).github/workflows/ci.yml'
          if git diff --cached --quiet; then
            echo "changed=false" >> "$GITHUB_OUTPUT"
            exit 0
          fi

          BRANCH_NAME="modernize-upgrade-${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT}"
          git switch -c "$BRANCH_NAME"
          git commit -m "chore: apply Modernize CLI upgrades"
          gh auth setup-git
          git push origin "HEAD:refs/heads/$BRANCH_NAME"
          echo "changed=true" >> "$GITHUB_OUTPUT"
          echo "branch_name=$BRANCH_NAME" >> "$GITHUB_OUTPUT"
# This only runs if changes were pushed. It creates a PR from the result branch into the default branch
      - name: Create modernization pull request
        if: steps.push_changes.outputs.changed == 'true'
        id: pull_request
        env:
          GH_TOKEN: ${{ github.token }}
          RESULT_BRANCH: ${{ steps.push_changes.outputs.branch_name }}
          BASE_BRANCH: ${{ github.event.repository.default_branch }}
        run: |
          {
            echo "## Modernization"
            printf '\nRequested target: %s\n' "$UPGRADE_TARGET"
            printf '\n[Workflow run](%s/%s/actions/runs/%s)\n' \
              "$GITHUB_SERVER_URL" "$GITHUB_REPOSITORY" "$GITHUB_RUN_ID"
            echo
            echo "Includes the CLI's committed changes and any remaining working-tree changes."
            echo "Only ci.yml changes are retained under .github/workflows."
            echo "Review the diff, CLI reports, and build/test results before merging."
          } > "$RUNNER_TEMP/modernize-pr-body.md"
          PR_URL=$(gh pr create --repo "$GITHUB_REPOSITORY" \
            --base "$BASE_BRANCH" --head "$RESULT_BRANCH" \
            --title "chore: modernize application ($UPGRADE_TARGET)" \
            --body-file "$RUNNER_TEMP/modernize-pr-body.md")
          echo "url=$PR_URL" >> "$GITHUB_OUTPUT"
# Only runs if changes were created. Manually triggers the repo’s ci.yml workflow against the modernization branch.
# This  workflow does not directly build/test the project itself; it delegates validation to the existing CI workflow
      - name: Run build and tests on result branch
        if: steps.push_changes.outputs.changed == 'true'
        env:
          GH_TOKEN: ${{ github.token }}
          RESULT_BRANCH: ${{ steps.push_changes.outputs.branch_name }}
        run: gh workflow run ci.yml --repo "$GITHUB_REPOSITORY" --ref "$RESULT_BRANCH"
# Writes a summary to the GitHub Actions run page
      - name: Display results summary
        if: always() && steps.push_changes.outcome == 'success'
        env:
          CHANGED: ${{ steps.push_changes.outputs.changed }}
          RESULT_BRANCH: ${{ steps.push_changes.outputs.branch_name }}
          BASE_BRANCH: ${{ github.event.repository.default_branch }}
          PR_URL: ${{ steps.pull_request.outputs.url }}
        run: |
          {
            echo "## Modernization results"
            printf '\nTarget: %s\n' "$UPGRADE_TARGET"
            if [ "$CHANGED" = "true" ]; then
              printf '\nResult branch: %s\n' "$RESULT_BRANCH"
              printf '\n[View branch](%s/%s/tree/%s)\n' \
                "$GITHUB_SERVER_URL" "$GITHUB_REPOSITORY" "$RESULT_BRANCH"
              if [ -n "$PR_URL" ]; then
                printf '\n[Pull request](%s)\n' "$PR_URL"
              else
                echo
                echo "Pull request creation failed; the result branch is preserved."
                printf '\n[Create pull request](%s/%s/compare/%s...%s)\n' \
                  "$GITHUB_SERVER_URL" "$GITHUB_REPOSITORY" "$BASE_BRANCH" "$RESULT_BRANCH"
              fi
              echo
              echo "Review the changes and run build/tests for the upgraded stack before merging."
            else
              echo
              echo "No net changes relative to the starting revision; no result branch or PR was created."
            fi
          } >> "$GITHUB_STEP_SUMMARY"
# Creates a Git bundle containing all local refs and commits.
# This is a recovery artifact in case something useful existed locally but was not pushed or exposed through the PR.
      - name: Preserve local commits
        if: always() && steps.baseline.outcome == 'success'
        run: git bundle create "$RUNNER_TEMP/modernize-result.bundle" --all
# Uploads the Modernize CLI logs and the recovery bundle as artifacts.
      - name: Upload Modernize CLI logs and recovery bundle
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: modernize-logs-${{ github.run_id }}-${{ github.run_attempt }}
          path: |
            ~/.modernize/logs/
            ${{ runner.temp }}/modernize-result.bundle
          if-no-files-found: warn
          retention-days: 7
```
{% endraw %}

### Review and commit

Review `.github/workflows/modernise.yml`, including the CLI installer, secret
names, permissions, and triggers. The workflow runs without interactive plan
approval and can create a branch and pull request. Do not commit until you
understand and approve that behaviour.

From your repository's default branch, commit and push the file:

```powershell
git add -- .github/workflows/modernise.yml
git commit -m "Add continuous modernization workflow"
git push
```

Confirm that **Java Continuous modernization** appears under **Actions**. If
you enabled automatic triggers, check for any runs that have already started
before starting another one.

## 8. Start the run

With the baseline checked and the workflows in place, run modernisation and
review the result. 

1. In your repository, open **Actions > Java Continuous modernization**.
2. Select **Run workflow** on the default branch and enter your agreed, supported upgrade target.
3. Follow the run through CLI installation, upgrade, result-branch creation, pull-request creation, and CI dispatch.

The example workflow checks out the repository's **default branch**, regardless
of the interactive branch used in module 01. It runs the CLI with `--no-tty`; there is no human
approval of the generated plan before execution. Human review happens at the
resulting pull request. The workflow does not merge it.

### What happens inside the modernisation workflow

Open the workflow run in **Actions** and expand its steps to follow the progress.
The same job runs whether it was started manually, by a push, or on its
schedule, if those triggers are enabled.

1. **Install and start the CLI:** The workflow downloads and runs the installer,
   then starts Modernize CLI. Open **Run Modernize CLI** to follow its output.
   The logs may show the CLI version and details similar to a local run.

2. **Set the input:** For a manual run, you can enter an upgrade target. Push
   and scheduled runs use the CLI's `latest` default. This workflow does not
   provide a model-selection input; model availability and configuration depend
   on the CLI and your organization's access.

3. **Prepare the upgrade:** The CLI examines the source in `src`. In this
   exercise, that's the Java todo app in your workshop repository. Review the
   logs to see what the CLI detects; the messages can vary between versions.

4. **Create the plan:** The CLI prepares an upgrade plan. You may see a
   **create java upgrade plan** skill mentioned in the logs. Unlike the
   interactive exercise, this run has no pause for a person to review and
   approve the plan before changes are made. That is an important trade-off to
   discuss; the resulting pull request is the human review point.

5. **Run the upgrade and validate:** The CLI attempts the upgrade and may run
   builds or tests as part of its work. Check its output for the actual results;
   a separate CI run is requested later for the result branch.

## 9. Review the result

### Review the branch and pull request

When the CLI produces changes, the workflow creates a branch named like:

```text
modernize-upgrade-<run_id>-<attempt>
```

It then attempts to open a pull request. For a `Java 21` target, the title
would be:

```text
chore: modernize application (Java 21)
```

Open the workflow summary and the pull request, then review the changed files:

* Check the target, changed files, generated reports, and any unresolved findings.
* Confirm that **Build and test** ran on the result branch and inspect its actual result.
* If you completed module 01, compare the result with its baseline and interactive plan.
* Decide what further testing and human approvals are required before a real merge.

### Check CI on the result branch

After creating the pull request, the workflow requests a run of `ci.yml` on the
result branch. Open **Actions > Build and test**, find that run, and check its
actual result. A request to run CI does not mean the build or tests passed; if
the dispatch fails, investigate and run the checks before continuing.

The modernisation result is not merged automatically. Review the pull request
and its validation results before deciding what to do next.

If the CLI produces no net change, the workflow reports that outcome and creates no
result branch or pull request. If pull-request creation fails after a branch was
pushed, the workflow summary points to the branch; investigate before proceeding.
Inspect the uploaded logs and recovery bundle when available, and treat their contents
as potentially sensitive.

### Troubleshooting

Modernisation is not always flawless. If the build fails after the
modernisation run, open the failed **Build and test** run and inspect the logs
to understand what went wrong.

For example, a build on a modernisation branch might fail with:

```text
UnsupportedClassVersionError: org/junit/platform/launcher/TagFilter has been compiled by a more recent version of the Java Runtime (class file version 61.0), this version of the Java Runtime only recognizes class file versions up to 52.0
```

In this example, a dependency needs Java 17 or later, but the build is running
with Java 8. This can happen when CI is still configured for the original app
after an upgrade. Check the JDK used in the CI logs and compare it with the
upgraded project's `src/pom.xml` and dependencies.

The CI example in step 5 reads `java.version` from `src/pom.xml` rather than
hardcoding a JDK. If that property is missing, it falls back to Java 8, so check
the detected version and confirm it is compatible with the upgraded project.
Adjust the project or workflow as needed; the right fix depends on the failure.

#### Fixing it with Copilot

You can ask Copilot to investigate a failed check and suggest a fix. For
example, in the [GitHub Copilot app](https://docs.github.com/en/copilot/get-started/quickstart-copilot-app):

1. Open the app and connect your workshop repository. You can also add it to a
   project if you want to organise related work.
2. Select **Pull requests**, open the modernisation PR, and choose **New
   session**. Alternatively, start a session on the result branch.
3. Ask Copilot to investigate the failed build and explain its proposed fix.
   Remove tokens, passwords, and other sensitive information before sharing logs.
4. Review the proposed changes and tests before updating the PR. Then run CI
   against the updated result branch and confirm that the new commit passes.

Disable **Java Continuous modernization** when finished. Remove the demonstration
secrets or revoke the short-lived tokens when they are no longer needed.

## 10. The takeaway: make modernisation continuous

The point is not just to upgrade this one application. It's to make keeping
applications current part of the SDLC.

We set the goal, let the agent plan, act, and observe, then validate the result
and bring it back for human review. Reusable tasks can retain what worked, and
scheduled runs can make the process repeatable when they're approved.

That's the shift: **from a once-a-decade rewrite to an ongoing modernisation
loop.**

### What changes

* **Scope:** Start with one repository and one pull request rather than a
  portfolio-wide programme.
* **Timeline:** Smaller changes can take days or weeks rather than months or
  years, although the actual time depends on the application.
* **Ownership:** The app team can work with agents rather than relying solely
  on a dedicated modernisation team.
* **Risk:** Build and test results on each iteration help identify problems
  earlier, but they don't replace human review or all other validation.
* **Knowledge:** Capture useful patterns as custom tasks so teams can reuse
  them instead of relearning them.

**Agents do the volume, people own the judgment.**

### Modernisation as part of the SDLC

Modernisation can become a recurring, multi-phase loop rather than a separate
project:

**Detect -> Assess -> Transform -> Validate -> Merge**

In this module, the workflow can make changes automatically, but a person still
reviews the pull request and decides whether it should be merged. The workflow
does not merge it for you.

### Getting started

* **Set appropriate triggers:** For example, a separate scheduled workflow
  could create an issue for modernisation. This lab's example runs the CLI
  directly; it does not create an issue.
* **Start small, then expand:** Begin with one repository and widen from there.
* **Integrate Modernize CLI into CI/CD:** Use a workflow like the one in this
  module, with triggers and permissions approved for your team.

## References

* [CI/CD integration with Modernize CLI](https://learn.microsoft.com/en-us/azure/developer/github-copilot-app-modernization/modernization-agent/cicd-integration?tabs=github-actions)
* [Modernize CLI quickstart](https://aka.ms/ghcp-modernization-agent)
* [Modernize CLI GitHub repository](https://github.com/microsoft/modernize-cli)
* [Modernize CLI commands](https://learn.microsoft.com/azure/developer/github-copilot-app-modernization/modernization-agent/cli-commands)

## Checkpoint

You can explain the actual automation trigger, source branch, plan-approval
limitation, CI result, and human review gate. A failed or skipped run is a learning
result to investigate, not a successful modernization.

[Next: create the Azure environment]({{ site.baseurl }}{% link appmod-lab/3-azure-environment/index.md %}) |
[Workshop home]({{ site.baseurl }}{% link index.md %})
