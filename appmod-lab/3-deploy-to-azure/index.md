---
title: Module 03 - Deploy to Azure
has_children: true
nav_order: 4
---

Provision and configure the Azure environment, then choose which Caldova
application to deploy. You can deploy Python or Java; both use the same
PostgreSQL database, workload identity, and shared build and deployment steps.

These steps create billable resources. Complete the
[prerequisites]({{ site.baseurl }}{% link appmod-lab/0-prerequisites/index.md %})
and agree on permissions, cost, and cleanup ownership before starting.

## Steps

1. [Provision and configure the Azure environment]({{ site.baseurl }}{% link appmod-lab/3-deploy-to-azure/deploy-to-azure-3-1-environment.md %})
2. Choose one application path:
   * [Deploy Python]({{ site.baseurl }}{% link appmod-lab/3-deploy-to-azure/deploy-to-azure-3-2-python.md %})
   * [Test and deploy Java]({{ site.baseurl }}{% link appmod-lab/3-deploy-to-azure/deploy-to-azure-3-3-java.md %})
3. Follow the [shared build, deploy, and verification steps]({{ site.baseurl }}{% link appmod-lab/3-deploy-to-azure/deploy-to-azure-3-4-deploy.md %}).

You only need one application path to continue to
[module 04 - Operate and improve]({{ site.baseurl }}{% link appmod-lab/4-operate-and-improve/index.md %}).
You can deploy both applications if you want to compare their behavior against
the same database.
