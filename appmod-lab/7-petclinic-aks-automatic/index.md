---
title: Module 07 - Modernize to AKS Automatic
has_children: true
nav_order: 8
---

Run Spring PetClinic locally with PostgreSQL, assess it with GitHub Copilot
modernization, and review the changes needed to deploy it on AKS Automatic.

After preparing Caldova in module 06, apply the same assessment and review
approach to a different Java app. Allow 120-150 minutes.

## Before you start

Continue from [module 06]({% link appmod-lab/6-caldova-source-modernization/index.md %}).
You also need
Docker Desktop with Linux containers, Docker Compose, and a JDK that matches
the PetClinic version agreed with your facilitator. The modernization tools
currently require Java 21 or later; keep a separate JDK for the app if needed.

PetClinic is not included in the downloaded starter apps. The exercise uses a
separate checkout of the public Spring PetClinic repository. For deployment, use
[module 03]({% link appmod-lab/3-azure-environment/index.md %}) or an approved
equivalent, with a separate PetClinic database, identity permissions, and namespace.

## Exercise

[Assess and migrate PetClinic]({% link appmod-lab/7-petclinic-aks-automatic/petclinic-aks-automatic-7-1-migrate.md %})

When you finish, go to
[module 08 - Cleanup]({% link appmod-lab/8-cleanup/index.md %}).
