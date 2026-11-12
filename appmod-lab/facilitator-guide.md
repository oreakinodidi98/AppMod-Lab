---
title: Facilitator guide
description: Prepare and deliver the application modernization workshop to customers.
ms.topic: how-to
nav_order: 10
---

## Prepare before the session

Meet the customer ahead of time to agree on the application story, participant
experience, approved subscription and region, spending limit, resource ownership,
and deletion time. Review the [prerequisites]({{ site.baseurl }}{% link appmod-lab/0-prerequisites/index.md %}) together.

Agree on each participant's owner code and instance on the
[Naming page]({{ site.baseurl }}{% link appmod-lab/0-prerequisites/prerequisite-0-2-naming.md %}).
Use different values where names would clash. `sc` means Sweden Central; check that
the selected services and quota are available there before accepting that default.

Participants create their own disposable repository and download the files needed
for each exercise from this public lab repository. `LAB_APP_REPO` points to their
local workshop repository. Neither this lab repository nor the original demo
repository needs to be cloned or forked.

* Confirm that each participant or pair can create a **new dedicated** resource group, AKS Automatic cluster, ACR, PostgreSQL flexible server, and managed identity, and can create the required registry and cluster role assignments.
* Check regional availability, quota, provider registration, organization policies, network egress, and access to public container and package registries.
* Check that the selected PostgreSQL public-access design is permitted and that participants know their workstation's public IPv4 address. Do not use real clinical data.
* Confirm GitHub Copilot access, the modernization extension, the source and target JDKs, and Maven. For the automated exercise, confirm GitHub Actions and token policies in a disposable repository.
* Decide whether participants work individually or in pairs. Agree on who pays for and deletes each environment.
* Rehearse the Azure setup and both application deployments in a separate approved subscription. Record actual timings and any policy-specific changes.

AKS, ACR, PostgreSQL, networking, and GitHub Actions can incur charges. Use the
[Azure pricing calculator](https://azure.microsoft.com/pricing/calculator/) and
the customer's cost controls; do not promise a fixed workshop cost.

## Suggested delivery

| Stage                    | Facilitator emphasis                                            | Checkpoint                                                 |
| ------------------------ | --------------------------------------------------------------- | ---------------------------------------------------------- |
| Welcome and preparation  | Set the business problem, safety boundaries, and expected costs | Everyone can access their repository and required tools    |
| Interactive Java upgrade | Baseline first, then assess and approve a bounded plan          | Participants can explain the target and validation plan    |
| Automated Java upgrade   | Contrast unattended plan execution with human PR review         | Participants can find the run, its result, and CI evidence |
| Azure environment        | Explain identities, network choices, and the disposable scope   | AKS, ACR, PostgreSQL, and workload identity are ready      |
| Deploy Caldova           | Let participants choose Python or Java; compare both if useful   | The chosen version returns the seeded inventory             |
| Operations and feedback  | Distinguish evidence, a hypothesis, and an approved action      | Participants produce a triaged follow-up                   |
| Caldova from source      | Assess the original app and review the changes needed for AKS    | Generated code and deployment pass the agreed checks         |
| PetClinic migration      | Apply the assessment and review approach to a different Java app | The deployed app uses its own database and preserves behavior |
| Cleanup                  | Confirm the owner and selected subscription before deletion     | Resource deletion is verified or explicitly handed off     |


## Prepare modules 06 and 07

These modules are part of the workshop flow. Allow 90-120 minutes for Caldova
source modernization and 120-150 minutes for PetClinic, plus the earlier modules
and Azure setup. Plan more than one session if needed. Keep the environment
until module 07 is complete, then clean up in module 08.

* [Module 06: Caldova from source]({{ site.baseurl }}{% link appmod-lab/6-caldova-source-modernization/index.md %}) downloads `Scenario1App` from this repository's assets, not the finished module 04 app. Run through local PostgreSQL setup and the Copilot changes before the session. Check that the generated app gets and renews Entra tokens before deploying it.

* [Module 07: PetClinic on AKS Automatic]({{ site.baseurl }}{% link appmod-lab/7-petclinic-aks-automatic/index.md %}) uses a separate upstream checkout. Agree on a source commit, compatible JDK, PostgreSQL profile, and Compose configuration ahead of time. Try the assessment with your installed extension; the screenshots and issue counts are examples.

* Give PetClinic a separate database and namespace. Decide whether participants transfer synthetic data or initialize a fresh database. Agree on validation and rollback before migration.

* Supply approved resource access, not shared user credentials. Do not copy broad Cluster Admin grants, fixed environment identifiers, or background Service Connector commands from the original lab.

* Gateway, custom DNS/TLS, Key Vault, Containerization Assist MCP, delivery automation, and AKS Desktop are optional extensions. Confirm platform ownership and availability before promising them as hands-on outcomes.

The source app is in `assets/Scenario1App`, and the PetClinic assessment
screenshots are in `assets/images`. The copied `AutomaticSetup.ps1`,
`ClassicSetup.ps1`, and `cleanup.ps1` in `assets/scripts` are demo references.
They can create or delete whole resource groups and do not use the participant
settings from module 03. Do not have students run them as workshop setup or cleanup.

Keep the shared Azure environment until every selected lab is complete, then
verify cleanup with its owner.

## Talking points and gates

Use modules [01]({{ site.baseurl }}{% link appmod-lab/1-interactive-modernization/index.md %}) and
[02]({{ site.baseurl }}{% link appmod-lab/2-automated-modernization/index.md %}) to introduce the two paths. The interactive path can
include plan approval, but the unattended CLI run has **no human plan-approval
gate**. Its human gate is review of the resulting pull request. Neither path proves
that a change is safe solely because an agent or build reports success.

For the final discussion, emphasize that the bug-hunter, telemetry, and
incident-response agents are conceptual roles; the workshop does not deploy them,
grant them production access, or perform autonomous remediation.

At each checkpoint, ask participants to show observable evidence: the baseline test
result, the target and plan, workflow status, healthy pods, API response, and the
human decision on a proposed follow-up.

## If something blocks the room

* If a participant cannot obtain GitHub Actions or token permissions, have them review a facilitator-owned run that was prepared and approved beforehand. Explain that they did not execute the automation themselves.
* If Azure quota, policy, permissions, or region availability blocks provisioning, pause the Azure exercises. Use a previously approved facilitator environment for a demonstration, and record that the participant did not provision their own resources.
* If PostgreSQL or workload identity is unavailable, inspect the failure in [the deployment exercise]({{ site.baseurl }}{% link appmod-lab/4-deploy-application/deploy-caldova.md %}). Do not switch to synthetic data or disable readiness checks without explaining the behavior change.
* If an image build or upgrade takes longer than planned, continue with the architecture and review discussion while it runs, then return to the result.
* If resources must be retained, name an owner and a deletion time. Ensure the owner has the values and access needed to finish [cleanup]({{ site.baseurl }}{% link appmod-lab/8-cleanup/index.md %}).

[Back to the workshop]({{ site.baseurl }}{% link index.md %})
