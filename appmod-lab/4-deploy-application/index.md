---
title: Module 04 - Deploy the application to Azure
has_children: true
nav_order: 5
---

Choose the Python or Java version of Caldova and deploy it to the AKS environment
from [module 03]({{ site.baseurl }}{% link appmod-lab/3-azure-environment/index.md %}).
Both versions use the same PostgreSQL database and workload identity.

## Choose your application

* [Deploy Python]({{ site.baseurl }}{% link appmod-lab/4-deploy-application/deploy-application-4-1-python.md %})
* [Test and deploy Java]({{ site.baseurl }}{% link appmod-lab/4-deploy-application/deploy-application-4-2-java.md %})

You only need to complete one path. Each path takes you through preparing its
files and then links to the
[shared build and deployment steps]({{ site.baseurl }}{% link appmod-lab/4-deploy-application/deploy-caldova.md %}).
You can also deploy Python first, then Java, to compare their responses against
the same database.

After your chosen app is working, continue to
[module 05 - Operate and improve]({{ site.baseurl }}{% link appmod-lab/5-operate-and-improve/index.md %}).
