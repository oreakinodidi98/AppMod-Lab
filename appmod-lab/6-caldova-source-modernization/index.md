---
title: Module 06 - Modernize Caldova from source
has_children: true
nav_order: 7
---

Start with the local Python Caldova app, then use Copilot to assess it and prepare
it for AKS. You create and review the container, identity, and deployment changes
instead of using the finished version from module 04.

In module 04, you deployed an app that was already prepared for AKS. Here, you
make those changes yourself with Copilot. Allow 90-120 minutes.

## Before you start

Continue from [module 05]({% link appmod-lab/5-operate-and-improve/index.md %}).
Keep the environment and lab settings from module 03. Install
Python 3.11 or later and PostgreSQL 15 or later for the local steps.
For deployment, complete [module 03]({% link appmod-lab/3-azure-environment/index.md %})
or use the equivalent environment already agreed with your facilitator.

The exercise downloads `Scenario1App` into your own workshop repository. It stays
separate from the Python and Java choices in module 04.

## Exercise

[Run, assess, and modernize Caldova]({% link appmod-lab/6-caldova-source-modernization/caldova-source-modernization-6-1-migrate.md %})

When you finish, continue with
[module 07 - PetClinic]({% link appmod-lab/7-petclinic-aks-automatic/index.md %}).
