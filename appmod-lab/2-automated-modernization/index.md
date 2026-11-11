---
title: Module 02 - Automate a modernization run
description: Run and review the repository's Java modernization workflow in a disposable fork.
ms.topic: tutorial
nav_order: 3
---

## Goals

Compare the interactive upgrade with the existing GitHub Actions workflow. Inspect
the resulting branch, pull request, and build evidence without merging the change.

## 1. Make the fork safe

The workflows in your fork are copies of the original repository's workflows. The
Caldova deployment and image-signing workflows contain values for the original demo
environment. The modernization workflow also has push and daily schedule triggers.
Do not enable these unchanged workflows or run them against a customer account.

1. In your **disposable fork**, open **Settings > Actions > General** and disable
   GitHub Actions for the repository before editing workflows or adding secrets.
   If you cannot do this, stop and ask the facilitator for an approved isolated run.
2. On the fork's default branch, inspect [the workflow directory](https://github.com/oreakinodidi98/AppMod-Lab/tree/main/.github/workflows).
   In the fork only, remove or move all workflow files out of `.github/workflows`
   except `ci.yml` and `modernise.yml`. This includes the deployment, signing,
   issue-to-project, and optional Copilot setup workflows. Do not edit the original
   repository.
3. In the fork's `modernise.yml`, remove the entire `push` and `schedule` entries
   under `on`, keeping `workflow_dispatch` and its `upgrade_target` input. Commit
   these safety changes to the fork's default branch while Actions is disabled.
4. Verify that only **Build and test** and **Java Continuous modernization** remain
   in the default branch's workflow directory, and that modernization has only the
   manual trigger. Build and test can still run on its configured pushes and pull
   requests. Review the Actions settings and branch protection with the owner.
5. Enable Actions in the fork only after those checks. Run workflows from the
   cleaned default branch and result branches based on it. Do not push an older
   interactive branch with the original workflows after enabling Actions unless
   you have made it safe as well.

If policy or branch protection prevents these changes, leave Actions disabled and
use a facilitator-owned demonstration instead.

## 2. Prepare authentication and CI

The existing workflow checks for two repository Actions secrets:

* `GH_TOKEN`: a GitHub personal access token authorized for the Copilot account used by Modernize CLI
* `CONTINUOUS_APPMOD_GH_TOKEN`: a token authorized to write repository contents and workflows in your fork so the result branch can be pushed

Create these through **Settings > Secrets and variables > Actions** in your fork,
using your organization's approved token policy, minimum scope, and short expiry.
Never put token values in source, a terminal transcript, a prompt, or a screenshot.
The built-in GitHub Actions token creates the pull request and dispatches CI; the
repository and organization must allow these operations.

Run or inspect **Build and test** on the fork's default branch. The modernization
workflow configures its own JDKs; the separate Copilot setup workflow is not a
prerequisite for its CLI job.

## 3. Start the run

1. In the fork, open **Actions > Java Continuous modernization**.
2. Select **Run workflow** on the default branch and enter your agreed, supported upgrade target.
3. Follow the run through CLI installation, upgrade, result-branch creation, pull-request creation, and CI dispatch.

The workflow checks out the fork's **default branch**, regardless of the interactive
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

[Next: create the Azure environment](../3-azure-environment/) |
[Workshop home](../../index.md)
