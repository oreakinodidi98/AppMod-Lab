---
title: Run and review the workflow
description: Run and review a Java modernization workflow in your workshop repository.
ms.topic: tutorial
parent: Module 02 - Automate a modernization run
nav_order: 1
---

## Goals

Compare the interactive upgrade with a GitHub Actions workflow in your own
workshop repository. Inspect the resulting branch, pull request, and build evidence without merging the change.

## 1. Add the workflows

Finish module 01 first: your repository's default branch must contain the original
`src` app, committed and pushed before the interactive upgrade.

Use the PowerShell terminal from the prerequisites. If you opened a new terminal,
the workshop variables are not carried over. In your cloned repository, repeat
the commands in [Create your workshop repository]({{ site.baseurl }}{% link appmod-lab/0-prerequisites/prerequisite-0-1-technical.md %}#create-your-workshop-repository)
to set `LAB_APP_REPO`, then repeat [Get the setup command]({{ site.baseurl }}{% link appmod-lab/0-prerequisites/prerequisite-0-1-technical.md %}#get-the-setup-command)
to download the script, verify its hash, and review it.

Save your work on the interactive branch, then return to the repository root and
switch to your default branch. The example uses `main`; change it if your
default branch has a different name.

```powershell
Set-Location -LiteralPath $env:LAB_APP_REPO
git status --short
$defaultBranch = "main"
git switch $defaultBranch
```

Confirm that Git switched branches successfully before downloading the workflows:

```powershell
& $env:LAB_SETUP -Module automation
git status --short
```

If PowerShell says the expression after `&` is not valid, `LAB_SETUP` may not be
set in this terminal. Repeat **Get the setup command** above, then try the
download again from the repository root.

The setup adds only `ci.yml` and `modernise.yml`. Both are set to run **manually**;
it does not add the original deployment or image-signing workflows. Review both
files and confirm their only trigger is `workflow_dispatch` before committing them.
If either file already exists, setup stops without overwriting it.

```powershell
git add -- .github/workflows/ci.yml .github/workflows/modernise.yml
git commit -m "Add workshop modernization workflows"
git push
```

In your repository's **Settings > Actions > General**, check that Actions are
allowed and that workflows can create pull requests. If policy prevents this,
use a facilitator-owned demonstration instead.

## 2. Prepare authentication and CI

The existing workflow checks for two repository Actions secrets:

* `GH_TOKEN`: a GitHub personal access token authorized for the Copilot account used by Modernize CLI
* `CONTINUOUS_APPMOD_GH_TOKEN`: a token authorized to write repository contents and workflows in your workshop repository so the result branch can be pushed

Create these through **Settings > Secrets and variables > Actions** in your repository,
using your organization's approved token policy, minimum scope, and short expiry.
Never put token values in source, a terminal transcript, a prompt, or a screenshot.
The built-in GitHub Actions token creates the pull request and dispatches CI; the
repository and organization must allow these operations.

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
* Compare the result with the baseline and the interactive plan from module 01.
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
