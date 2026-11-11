---
title: Application modernization with GitHub Copilot and AKS
description: A full-day, facilitator-led workshop for modernizing applications and operating them on Azure Kubernetes Service.
ms.topic: tutorial
---

## Workshop overview

Take two related journeys through application modernization:

1. Assess and upgrade a Java 8 todo application with GitHub Copilot modernization. Compare an interactive, human-approved plan with an automated GitHub Actions run.
2. Build and deploy the Python and Java versions of Caldova, a clinical inventory application, to Azure Kubernetes Service (AKS). Both versions use the same PostgreSQL data and application contract.

Finish by investigating a workload and discussing how operational feedback becomes
reviewed engineering work. The agent roles in the discussion are a proposed operating
model, not agents installed by this repository.

The workshop is designed for customers working with a Cloud Solution Architect (CSA).
Participants can work individually or in pairs. A basic understanding of Git, web
applications, containers, and Kubernetes is useful.

## Learning outcomes

By the end, you can:

* Establish a baseline, review an upgrade plan, and validate an agent-generated change.
* Explain where human approval occurs in the interactive and automated paths.
* Provision a disposable AKS, Azure Container Registry (ACR), and PostgreSQL environment using your own settings.
* Build both Caldova implementations and verify their API and web behavior on AKS.
* Use Microsoft Entra Workload ID for database access without a stored database password.
* Inspect workload health and propose a human-reviewed response to an operational signal.
* Remove the workshop resources and disable the demonstration automation.

## Workshop journey

Times are estimates for hands-on work. Allow about 60 minutes for lunch and breaks,
and more time if cloud provisioning, permissions, or image builds are slow.

| Module                                  | Topic                        | Time    | Outcome                                                     |
| --------------------------------------- | ---------------------------- | ------- | ----------------------------------------------------------- |
| [00](./00-prerequisites.md)             | Prepare                      | 20 min  | Tools, access, and a disposable fork are ready              |
| [01](./01-interactive-modernization.md) | Interactive modernization    | 60 min  | Baseline and review a Java upgrade plan                     |
| [02](./02-automated-modernization.md)   | Automated modernization      | 45 min  | Inspect a workflow run, result, and review gate             |
| [03](./03-azure-environment.md)         | Create the Azure environment | 100 min | A dedicated AKS, registry, database, and identity are ready |
| [04](./04-python-application.md)        | Modernize Caldova Python     | 50 min  | Build and deploy the Python implementation                  |
| [05](./05-java-application.md)          | Modernize Caldova Java       | 50 min  | Deploy Java against the same database and compare behavior  |
| [06](./06-operate-and-improve.md)       | Operate and improve          | 45 min  | Inspect health and practice a human-triaged feedback loop   |
| [07](./07-cleanup.md)                   | Clean up                     | 20 min  | Remove workshop resources and credentials                   |

Modules 04 and 05 both use the [shared deployment exercise](./deploy-caldova.md).
Complete module 03 before either application module. Module 05 can be done without
module 04, but doing both makes the comparison more useful. The modernization
modules use the separate todo application in [`src`](../src/), not Caldova.

## Before you start

Read [prerequisites](./00-prerequisites.md). The Azure exercises create billable
resources in a new, dedicated resource group. Agree on a budget, ownership, region,
permissions, and deletion with the customer before provisioning.

> [!IMPORTANT]
> The existing root-level setup scripts, deployment workflows, and `k8s` manifests
> contain values for a particular demonstration environment. Do not run or apply
> them for this workshop. The workshop uses your own inputs and its own deployment
> template instead.

The workshop intentionally uses a public AKS API endpoint, a PostgreSQL public
endpoint restricted to specified IPv4 addresses, and `kubectl port-forward`. This is
a short-lived learning environment, not a production reference architecture. If
customer policy prohibits this network design, stop and work with the platform team
on an approved private design rather than weakening the policy.

## Facilitator resources

* [Facilitator guide](./FACILITATOR.md)
* [Agent-assisted SDLC background and diagrams](../Agentic_SDLC/notes.md)
* [GitHub Copilot modernization quickstart](https://learn.microsoft.com/azure/developer/github-copilot-app-modernization/quickstart-upgrade)
* [AKS Automatic quickstart](https://learn.microsoft.com/azure/aks/automatic/quick-automatic-managed-network)

[Start with module 00](./00-prerequisites.md)
