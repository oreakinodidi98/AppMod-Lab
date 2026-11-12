---
title: Application modernization with GitHub Copilot and AKS
description: A facilitator-led workshop for modernizing applications and operating them on Azure Kubernetes Service.
layout: home
nav_exclude: true
---

New here? Read [About this workshop]({{ site.baseurl }}{% link about.md %}) for an overview,
learning resources, and the sample apps.

Work through application modernization from assessment to deployment:

1. Assess and upgrade a Java todo application with GitHub Copilot modernization. Compare an interactive, human approved plan with an automated GitHub Actions run.
2. Choose the Python or Java version of Caldova, a clinical inventory app, and deploy it to Azure Kubernetes Service (AKS). You can try both to compare their behavior.
3. Inspect the running app, then use Copilot to prepare the original Caldova source for AKS and migrate Spring PetClinic.

Finish by cleaning up the workshop environment. The agent roles in the operations
discussion are a proposed operating model, not agents installed by this repository.

## Interactive and automated modernization

[![An engineer working in an editor or terminal and an automated engineering task feed into a shared modernization process with instructions, artifacts, and human review.]({{ '/assets/images/agentic-sdlc.png' | relative_url }})]({{ '/assets/images/agentic-sdlc.png' | relative_url }})

**What this shows:** Two ways to start modernization work: interactively from
your editor or terminal, or through an automated engineering task. Select the
diagram to view it full size.

The diagram is a comparison, not a shared service installed by this
workshop. In module 01, you approve the plan before changes are made. In module
02, you start a GitHub Actions workflow manually and review its changes in a
pull request. Both need human review, but at different points.

## Workshop modules

| Module | Topic |
| --- | --- |
| [00 - Prepare]({{ site.baseurl }}{% link appmod-lab/0-prerequisites/index.md %}) | Tools, access, your repository, and resource naming |
| [01 - Interactive modernization]({{ site.baseurl }}{% link appmod-lab/1-interactive-modernization/index.md %}) | Run an assessment and review a Java upgrade plan |
| [02 - Automated modernization]({{ site.baseurl }}{% link appmod-lab/2-automated-modernization/index.md %}) | Inspect a workflow run, result, and review gate |
| [03 - Azure environment]({{ site.baseurl }}{% link appmod-lab/3-azure-environment/index.md %}) | Create a dedicated AKS, registry, database, and identity |
| [04 - Deploy the application to Azure]({{ site.baseurl }}{% link appmod-lab/4-deploy-application/index.md %}) | Choose Python or Java, then build, deploy, and verify it |
| [05 - Operate and improve]({{ site.baseurl }}{% link appmod-lab/5-operate-and-improve/index.md %}) | Inspect health and practice a human-triaged feedback loop |
| [06 - Modernize Caldova from source]({{ site.baseurl }}{% link appmod-lab/6-caldova-source-modernization/index.md %}) | Assess the original Python app and prepare it for AKS |
| [07 - Modernize PetClinic for AKS Automatic]({{ site.baseurl }}{% link appmod-lab/7-petclinic-aks-automatic/index.md %}) | Assess a different Java app and migrate it to AKS Automatic |
| [08 - Cleanup]({{ site.baseurl }}{% link appmod-lab/8-cleanup/index.md %}) | Remove workshop resources and temporary credentials |

Each module has an overview page with links to its exercise files.
Follow the modules in order. In module 04, choose either the Python or Java
path; both use the [shared deployment steps]({{ site.baseurl }}{% link appmod-lab/4-deploy-application/deploy-caldova.md %}).
You can deploy both if you want to compare them, but one working deployment is
enough to continue to module 05.

## Application source

The starter files for the Java todo app, Python Caldova, Java Caldova, and the
original Caldova source app are
stored in this public lab repository. In module 00, create your own disposable
repository and set `LAB_APP_REPO` to its local copy. Each exercise tells you
which files to download. You don't need to fork or clone the lab repository.

## Before you start

Read [the prerequisites]({{ site.baseurl }}{% link appmod-lab/0-prerequisites/index.md %}). The Azure exercises create billable resources in a new, dedicated resource group. Agree on a budget, ownership, region, permissions, and deletion with the customer before provisioning.

The workshop intentionally uses a public AKS API endpoint, a PostgreSQL public endpoint restricted to specified IPv4 addresses, and `kubectl port-forward`. This is a short-lived learning environment, not a production reference architecture. If customer policy prohibits this network design, stop and work with the platform team on an approved private design rather than weakening the policy.

## Plan your time

Agree on a schedule with your facilitator. For Modules 06 and 07 allow about 90-120 minutes for Caldova source modernization and 120-150 minutes for PetClinic, in addition to the earlier modules and Azure setup time. You may want to split the workshop across sessions.

Keep the Azure environment until the end of module 07, then complete cleanup in
module 08. If you pause between sessions, agree on who owns the resources, the
cost limit, and when they will be deleted.

## Facilitator resources

* [Facilitator guide]({{ site.baseurl }}{% link appmod-lab/facilitator-guide.md %})
* [GitHub Copilot modernization quickstart](https://learn.microsoft.com/azure/developer/github-copilot-app-modernization/quickstart-upgrade)
* [AKS Automatic quickstart](https://learn.microsoft.com/azure/aks/automatic/quick-automatic-managed-network)

[Start with module 00]({{ site.baseurl }}{% link appmod-lab/0-prerequisites/index.md %})
