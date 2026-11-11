---
title: Facilitator guide
description: Prepare and deliver the application modernization workshop to customers.
ms.topic: how-to
---

## Prepare before the session

Meet the customer ahead of time to agree on the application story, participant
experience, approved subscription and region, spending limit, resource ownership,
and deletion time. Review the [prerequisites](./00-prerequisites.md) together.

* Confirm that each participant or pair can create a **new dedicated** resource group, AKS Automatic cluster, ACR, PostgreSQL flexible server, and managed identity, and can create the required registry and cluster role assignments.
* Check regional availability, quota, provider registration, organization policies, network egress, and access to public container and package registries.
* Check that the selected PostgreSQL public-access design is permitted and that participants know their workstation's public IPv4 address. Do not use real clinical data.
* Confirm GitHub Copilot access, the modernization extension, the source and target JDKs, and Maven. For the automated exercise, confirm GitHub Actions and token policies in a disposable fork.
* Decide whether participants work individually or in pairs. Agree on who pays for and deletes each environment.
* Rehearse the Azure setup and both application deployments in a separate approved subscription. Record actual timings and any policy-specific changes.

AKS, ACR, PostgreSQL, networking, and GitHub Actions can incur charges. Use the
[Azure pricing calculator](https://azure.microsoft.com/pricing/calculator/) and
the customer's cost controls; do not promise a fixed workshop cost.

## Suggested delivery

| Stage                    | Facilitator emphasis                                            | Checkpoint                                                 |
| ------------------------ | --------------------------------------------------------------- | ---------------------------------------------------------- |
| Welcome and preparation  | Set the business problem, safety boundaries, and expected costs | Everyone can access the fork and required tools            |
| Interactive Java upgrade | Baseline first, then assess and approve a bounded plan          | Participants can explain the target and validation plan    |
| Automated Java upgrade   | Contrast unattended plan execution with human PR review         | Participants can find the run, its result, and CI evidence |
| Azure environment        | Explain identities, network choices, and the disposable scope   | AKS, ACR, PostgreSQL, and workload identity are ready      |
| Caldova Python and Java  | Show one API contract and database with two implementations     | Both versions return the seeded inventory                  |
| Operations and feedback  | Distinguish evidence, a hypothesis, and an approved action      | Participants produce a triaged follow-up                   |
| Cleanup                  | Confirm the owner and selected subscription before deletion     | Resource deletion is verified or explicitly handed off     |

## Talking points and gates

Use the [interactive and automated flow diagram](../Agentic_SDLC/images/image.png)
to introduce the two paths. The diagram shows an intended common operating model.
In the workflow actually checked into this repository, the interactive path can
include plan approval, but the unattended CLI run has **no human plan-approval
gate**. Its human gate is review of the resulting pull request. Neither path proves
that a change is safe solely because an agent or build reports success.

Use the [post-production diagram](../Agentic_SDLC/images/image-1.png) for the final
discussion. The bug-hunter, telemetry, and incident-response agents are conceptual
roles; the workshop does not deploy them, grant them production access, or perform
autonomous remediation.

At each checkpoint, ask participants to show observable evidence: the baseline test
result, the target and plan, workflow status, healthy pods, API response, and the
human decision on a proposed follow-up.

## If something blocks the room

* If a participant cannot obtain GitHub Actions or token permissions, have them review a facilitator-owned run that was prepared and approved beforehand. Explain that they did not execute the automation themselves.
* If Azure quota, policy, permissions, or region availability blocks provisioning, pause the Azure exercises. Use a previously approved facilitator environment for a demonstration, and record that the participant did not provision their own resources.
* If PostgreSQL or workload identity is unavailable, inspect the failure in [the deployment exercise](./deploy-caldova.md). Do not switch to synthetic data or disable readiness checks without explaining the behavior change.
* If an image build or upgrade takes longer than planned, continue with the architecture and review discussion while it runs, then return to the result.
* If resources must be retained, name an owner and a deletion time. Ensure the owner has the values and access needed to finish [cleanup](./07-cleanup.md).

[Back to the workshop](./README.md)
