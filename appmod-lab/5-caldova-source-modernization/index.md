---
title: Module 05 - Modernize Caldova
has_children: true
nav_order: 6
---

Start with the local Python Caldova app, then use Copilot to assess it and prepare
it for AKS. You create and review the container, identity, and deployment changes
instead of using the already-prepared application from module 03.

In module 03, you deployed an app that was already prepared for AKS. Here, you
make those changes yourself with Copilot. Allow 90-120 minutes.

## Before you start

Continue from [module 04]({{ site.baseurl }}{% link appmod-lab/4-operate-and-improve/index.md %}).
Keep the environment and lab settings from module 03. Install
Python 3.11 or later and PostgreSQL 15 or later for the local steps.
For deployment, complete [module 03]({{ site.baseurl }}{% link appmod-lab/3-deploy-to-azure/index.md %})
or use the equivalent environment already agreed with your facilitator.

The exercise downloads `Scenario1App` into your own workshop repository. It stays
separate from the Python and Java choices in module 03.

## Exercise

[Run, assess, and modernize Caldova]({{ site.baseurl }}{% link appmod-lab/5-caldova-source-modernization/caldova-source-modernization-5-1-migrate.md %})

When you finish, continue with
[module 06 - PetClinic]({{ site.baseurl }}{% link appmod-lab/6-petclinic-aks-automatic/index.md %}).
