---
title: About this workshop
description: Learn what this application modernization workshop covers and where to find more resources.
nav_order: 0
---

# About this workshop

<img src="{{ '/assets/images/Github_Copilot_Modernization_logo.png' | relative_url }}" alt="GitHub Copilot modernization logo" width="160">

This guided workshop takes you through modernizing applications with GitHub
Copilot and running them on Azure Kubernetes Service (AKS). You will assess a
Java app, review an upgrade plan, try an automated GitHub Actions workflow, and
choose a Python or Java app to deploy with PostgreSQL and no stored database password.

The aim is a practical, 200-level understanding of application modernization.
The steps are provided, but you should be comfortable with Git, a terminal, basic
application development, containers, and Azure. You do not need to be an AKS expert.
You will review the changes Copilot suggests and test the app before moving on.

You will also modernize Caldova from source and migrate Spring PetClinic to AKS
Automatic. These are part of the main workshop flow. Agree on the schedule with
your facilitator; the full workshop can be split across sessions.

> **Important:** Start with the
> [prerequisites]({{ site.baseurl }}{% link appmod-lab/0-prerequisites/index.md %}). You need your
> own GitHub account, GitHub Copilot access, and an approved Azure subscription
> with the required permissions. Azure resources and image builds can incur
> charges. Agree on a budget and clean up when you finish.

## What you will work on

* **Assess and upgrade:** Run an assessment on a Java repository and review the plan before making changes.
* **Automate and review:** Compare the interactive upgrade with a GitHub Actions run and review the result.
* **Choose and deploy:** Run the Python or Java version of Caldova on AKS. Try both if you want to compare them against the same database.
* **Check and improve:** Inspect workload health, investigate a problem, and decide what to change next.
* **Modernize from source:** Generate and test the changes needed to move the original Caldova app and Spring PetClinic to AKS Automatic.

Create your own workshop repository and download the starter files as each lab
needs them. You do not need to fork or clone this lab repository. PetClinic is the
exception: module 07 uses a separate upstream checkout.

[View the workshop modules]({{ site.baseurl }}{% link index.md %})

## Learn more

Explore the official documentation for the topics covered here:

* **Java assessment and migration:** [GitHub Copilot modernization quickstart](https://learn.microsoft.com/azure/developer/java/migration/migrate-github-copilot-app-modernization-for-java-quickstart-assess-migrate)
* **Assessment reports:** [Working with assessment in VS Code](https://learn.microsoft.com/azure/developer/java/migration/migrate-github-copilot-app-modernization-for-java-working-with-assessment)
* **AKS Automatic:** [Create an AKS Automatic cluster](https://learn.microsoft.com/azure/aks/automatic/quick-automatic-managed-network)
* **Container images:** [Build images with Azure Container Registry Tasks](https://learn.microsoft.com/azure/container-registry/container-registry-tutorial-quick-task)
* **Workload identity:** [Use Microsoft Entra Workload ID with AKS](https://learn.microsoft.com/azure/aks/workload-identity-overview)
* **PostgreSQL authentication:** [Microsoft Entra authentication for Azure Database for PostgreSQL](https://learn.microsoft.com/azure/postgresql/flexible-server/concepts-azure-ad-authentication)
* **GitHub Actions and Azure:** [Connect to Azure with OpenID Connect](https://learn.microsoft.com/azure/developer/github/connect-from-azure-openid-connect)
* **Resource naming:** [Define an Azure naming convention](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)

## Samples

The workshop uses these apps:

* [Java todo app](https://github.com/oreakinodidi98/AppMod-Lab/tree/main/assets/src): the starting point for the interactive and automated upgrades.
* [Caldova Python](https://github.com/oreakinodidi98/AppMod-Lab/tree/main/assets/Python_app) and [Caldova Java](https://github.com/oreakinodidi98/AppMod-Lab/tree/main/assets/Java_app): two versions of the same inventory app.
* [Caldova source app](https://github.com/oreakinodidi98/AppMod-Lab/tree/main/assets/Scenario1App): the version you prepare for AKS in module 06.
* [Spring PetClinic](https://github.com/spring-projects/spring-petclinic): the separate Java app used in module 07.

Use synthetic data only. These are learning exercises, not production-ready
deployment templates.

## Diagrams

For diagrams showing a production AKS design, see the
[AKS baseline architecture](https://learn.microsoft.com/azure/architecture/reference-architectures/containers/aks/baseline-aks).
Compare it with the simpler environment you create in
[module 03]({{ site.baseurl }}{% link appmod-lab/3-azure-environment/index.md %}).
This workshop uses public endpoints with restricted access and local port
forwarding; it does not implement that production architecture.

## Contributors

Maintained by [@oreakinodidi98](https://github.com/oreakinodidi98).
Suggestions and contributions are welcome through the
[workshop repository](https://github.com/oreakinodidi98/AppMod-Lab).

The workshop layout is inspired by the
[Azure API Management guided lab](https://github.com/Azure/apim-lab).
The PetClinic exercise uses the Spring community's sample application.

## Trademarks

Product names and logos belong to their respective owners. Use of Microsoft
trademarks must follow
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Third-party names and logos are subject to their owners' policies. Their use here
does not imply sponsorship or endorsement.

[Start with the prerequisites]({{ site.baseurl }}{% link appmod-lab/0-prerequisites/index.md %})
