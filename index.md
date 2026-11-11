---
title: Application modernization with GitHub Copilot and AKS
description: A full-day, facilitator-led workshop for modernizing applications and operating them on Azure Kubernetes Service.
layout: home
nav_exclude: true
---

Take two related journeys through application modernization:

1. Assess and upgrade a Java todo application with GitHub Copilot modernization. Compare an interactive, human-approved plan with an automated GitHub Actions run.
2. Build and deploy Python and Java versions of Caldova, a clinical inventory application, to Azure Kubernetes Service (AKS). Both versions use the same PostgreSQL data and application contract.

Finish by investigating a workload and discussing how operational feedback becomes reviewed engineering work. The agent roles in the discussion are a proposed operating model, not agents installed by this repository.

## Workshop modules

| Module | Topic |
| --- | --- |
| [00 - Prepare]({% link appmod-lab/0-prerequisites/index.md %}) | Tools, access, and a disposable fork |
| [01 - Interactive modernization]({% link appmod-lab/1-interactive-modernization/index.md %}) | Establish a baseline and review a Java upgrade plan |
| [02 - Automated modernization]({% link appmod-lab/2-automated-modernization/index.md %}) | Inspect a workflow run, result, and review gate |
| [03 - Azure environment]({% link appmod-lab/3-azure-environment/index.md %}) | Create a dedicated AKS, registry, database, and identity |
| [04 - Caldova Python]({% link appmod-lab/4-python-application/index.md %}) | Build and deploy the Python implementation |
| [05 - Caldova Java]({% link appmod-lab/5-java-application/index.md %}) | Deploy Java against the same database and compare behavior |
| [06 - Operate and improve]({% link appmod-lab/6-operate-and-improve/index.md %}) | Inspect health and practice a human-triaged feedback loop |
| [07 - Cleanup]({% link appmod-lab/7-cleanup/index.md %}) | Remove workshop resources and credentials |

Each module has an overview page with links to its exercise files.
Modules 04 and 05 both use the [shared deployment exercise]({% link appmod-lab/4-python-application/deploy-caldova.md %}). Complete module 03 before either application module. Module 05 can be done without module 04, but doing both makes the comparison more useful.

## Application source

The applications are maintained in [AKS_AppMod_Demos](https://github.com/oreakinodidi98/AKS_AppMod_Demos):

* [Java todo application](https://github.com/oreakinodidi98/AKS_AppMod_Demos/tree/main/src) for the modernization exercises
* [Python Caldova](https://github.com/oreakinodidi98/AKS_AppMod_Demos/tree/main/Python_app)
* [Java Caldova](https://github.com/oreakinodidi98/AKS_AppMod_Demos/tree/main/Java_app)

Follow module 00 to create a disposable application fork and set `LAB_APP_REPO`
to its local clone. `LAB_REPO` points to the separate `AppMod-Lab` documentation
clone, which contains the workshop deployment template.

## Before you start

Read [the prerequisites]({% link appmod-lab/0-prerequisites/index.md %}). The Azure exercises create billable resources in a new, dedicated resource group. Agree on a budget, ownership, region, permissions, and deletion with the customer before provisioning.

The workshop intentionally uses a public AKS API endpoint, a PostgreSQL public endpoint restricted to specified IPv4 addresses, and `kubectl port-forward`. This is a short-lived learning environment, not a production reference architecture. If customer policy prohibits this network design, stop and work with the platform team on an approved private design rather than weakening the policy.

## Facilitator resources

* [Facilitator guide]({% link appmod-lab/facilitator-guide.md %})
* [GitHub Copilot modernization quickstart](https://learn.microsoft.com/azure/developer/github-copilot-app-modernization/quickstart-upgrade)
* [AKS Automatic quickstart](https://learn.microsoft.com/azure/aks/automatic/quick-automatic-managed-network)

[Start with module 00]({% link appmod-lab/0-prerequisites/index.md %})
