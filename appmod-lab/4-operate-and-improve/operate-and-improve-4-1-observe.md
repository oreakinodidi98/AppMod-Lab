---
title: Observe, recover, and propose a follow-up
description: Inspect Caldova health and practice a human-reviewed operational feedback loop.
ms.topic: tutorial
parent: Module 04 - Operate and improve
nav_order: 1
---

## Goals

Observe the deployed application, practice a bounded recovery exercise, and turn an
operational signal into a proposed engineering action. This module requires a
successful Python or Java deployment from
[module 03]({{ site.baseurl }}{% link appmod-lab/3-deploy-to-azure/index.md %}).

## 1. Inspect the workload

In the PowerShell terminal used for module 03, the same settings remain
available. Confirm the Kubernetes context, then inspect only your workshop
namespace:

If that terminal was closed, restore the module 03 PowerShell settings from
`.envrc` first. Do not rerun the resource creation commands.

```powershell
kubectl config current-context
kubectl get deployments,pods,services --namespace $env:MANAGED_NAMESPACE_NAME
kubectl describe "deployment/$env:API_NAME" --namespace $env:MANAGED_NAMESPACE_NAME
kubectl logs "deployment/$env:API_NAME" --namespace $env:MANAGED_NAMESPACE_NAME --tail=50
```

Compare the pod status and events with the API's `/live`, `/health`, and
`/materials` results from the deployment exercise. The web service can return an
HTML page even when it cannot retrieve inventory. What evidence would distinguish
an application process failure, a database connection failure, and an image-pull
failure?

Treat logs as potentially sensitive. Do not copy tokens or customer data into
Copilot prompts, tickets, or screenshots. AKS Automatic can enable Azure monitoring
by default; check the actual configuration before relying on it. The lab does not
configure an incident-response agent or an automated response to alerts.

## 2. Observe a controlled recovery

The following exercise scales only the workshop web deployment to two replicas,
then asks you to delete one selected web pod. Kubernetes should replace it. A
port forward can still disconnect because it targets an individual pod; this is
not a high-availability or load test.

```powershell
kubectl scale deployment $env:WEB_NAME --namespace $env:MANAGED_NAMESPACE_NAME --replicas=2
kubectl rollout status "deployment/$env:WEB_NAME" --namespace $env:MANAGED_NAMESPACE_NAME --timeout=10m
kubectl get pods --namespace $env:MANAGED_NAMESPACE_NAME `
    --selector "app.kubernetes.io/name=$env:WEB_NAME"
```

Confirm that two web pods are ready. Copy the name of one of those pods and
enter it below. Check the name and namespace before deleting it; do not delete
a pod from another application.

```powershell
$selectedPod = Read-Host 'Name of the workshop web pod to delete'
kubectl get pod --namespace $env:MANAGED_NAMESPACE_NAME `
    --selector "app.kubernetes.io/name=$env:WEB_NAME" `
    --field-selector "metadata.name=$selectedPod"
```

Confirm that the command lists the selected web pod. If it does not, stop and
select a pod from the earlier list. Delete only the matching pod:

```powershell
kubectl delete pod --namespace $env:MANAGED_NAMESPACE_NAME `
    --selector "app.kubernetes.io/name=$env:WEB_NAME" `
    --field-selector "metadata.name=$selectedPod"
kubectl rollout status "deployment/$env:WEB_NAME" --namespace $env:MANAGED_NAMESPACE_NAME --timeout=10m
kubectl get pods --namespace $env:MANAGED_NAMESPACE_NAME `
    --selector "app.kubernetes.io/name=$env:WEB_NAME"
```

Confirm that the deleted pod name is gone, a new pod has appeared, and both
web pods are ready.
Restart the web port forward if it disconnected, then check the web page again.
If replacement fails, inspect events and quota rather than assuming recovery.

Return the lab to one web replica after the exercise:

```powershell
kubectl scale deployment $env:WEB_NAME --namespace $env:MANAGED_NAMESPACE_NAME --replicas=1
kubectl rollout status "deployment/$env:WEB_NAME" --namespace $env:MANAGED_NAMESPACE_NAME --timeout=10m
```

The manifest also specifies one replica, so reapplying it returns the deployment to
that setting. A production replica count and availability design require separate
capacity and resilience decisions.

## 3. Turn a signal into reviewed work

Discuss a possible operating model for turning an operational signal into reviewed
work. The telemetry, bug-hunter, and incident-response agents are conceptual; they
are not installed or authorized by this workshop. Kubernetes replacing a pod is a
controller action, not an AI agent remediation.

[![Production logs, metrics, feedback, and incidents feed into proactive checks, monitoring, and incident response, with human approval before new work or mitigation.]({{ '/assets/images/post-production-loop.png' | relative_url }})]({{ '/assets/images/post-production-loop.png' | relative_url }})

**What this shows:** Follow the arrows from a production signal to a proposed
action. The green diamonds are human decisions: triage decides whether to create
work or update instructions, and the on-call person decides whether to act on an
incident suggestion. Approved work feeds back into development or into a
mitigation, runbook, or communications update. Select the diagram to view it full
size.

In pairs, choose one observed or hypothetical signal, such as repeated database
readiness failures. Write a short handoff with:

1. The symptom, affected service, time, and evidence you would collect.
2. A plausible cause and at least one alternative that remains unverified.
3. The next safe investigation and the person who owns the decision.
4. A proposed fix, its tests, required approval, and rollback plan.

Discuss what an assistant could summarize and where a human must verify evidence,
approve changes, and decide whether production access is appropriate. Do not create
or run an autonomous remediation as part of this exercise.

## Checkpoint

You can distinguish process liveness, database readiness, and user-visible behavior;
describe the pod-replacement result; and present a human-triaged follow-up without
claiming the conceptual agents were deployed.

Keep the Azure environment for the remaining modules. Next, start with the
original Caldova source and prepare it for AKS.

[Next: modernize Caldova from source]({{ site.baseurl }}{% link appmod-lab/5-caldova-source-modernization/index.md %}) |
[Workshop home]({{ site.baseurl }}{% link index.md %})
