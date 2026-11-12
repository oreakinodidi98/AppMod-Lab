---
title: Observe, recover, and propose a follow-up
description: Inspect Caldova health and practice a human-reviewed operational feedback loop.
ms.topic: tutorial
parent: Module 05 - Operate and improve
nav_order: 1
---

## Goals

Observe the deployed application, practice a bounded recovery exercise, and turn an
operational signal into a proposed engineering action. This module requires a
successful Python or Java deployment from
[module 04]({{ site.baseurl }}{% link appmod-lab/4-deploy-application/index.md %}).

## 1. Inspect the workload

In the main lab PowerShell terminal, inspect only your workshop namespace:

```powershell
kubectl get deployments,pods,services --namespace $env:LAB_NAMESPACE
kubectl describe "deployment/$($env:LAB_API_NAME)" --namespace $env:LAB_NAMESPACE
kubectl logs "deployment/$($env:LAB_API_NAME)" --namespace $env:LAB_NAMESPACE --tail=50
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
kubectl scale deployment $env:LAB_WEB_NAME --namespace $env:LAB_NAMESPACE --replicas=2
kubectl rollout status "deployment/$($env:LAB_WEB_NAME)" --namespace $env:LAB_NAMESPACE --timeout=10m
$pods = @(kubectl get pods --namespace $env:LAB_NAMESPACE `
    --selector "app.kubernetes.io/name=$env:LAB_WEB_NAME" --output json |
    ConvertFrom-Json | Select-Object -ExpandProperty items)
if ($pods.Count -lt 2) { throw 'Two web pods are not available. Investigate before deleting one.' }
$selectedPod = $pods[0].metadata.name
"Selected workshop web pod: $selectedPod"
if ((Read-Host 'Type the selected pod name to delete it') -cne $selectedPod) {
    throw 'Pod deletion was not confirmed.'
}
kubectl delete pod $selectedPod --namespace $env:LAB_NAMESPACE
kubectl rollout status "deployment/$($env:LAB_WEB_NAME)" --namespace $env:LAB_NAMESPACE --timeout=10m
kubectl wait --for=condition=ready pods --namespace $env:LAB_NAMESPACE `
    --selector "app.kubernetes.io/name=$env:LAB_WEB_NAME" --timeout=5m
$replacementPods = @(kubectl get pods --namespace $env:LAB_NAMESPACE `
    --selector "app.kubernetes.io/name=$env:LAB_WEB_NAME" --output json |
    ConvertFrom-Json | Select-Object -ExpandProperty items)
if ($replacementPods.Count -lt 2 -or $selectedPod -in $replacementPods.metadata.name) {
    throw 'The expected replacement web pod is not ready. Inspect the deployment and events.'
}
$replacementPods | Select-Object @{Name='Pod'; Expression={ $_.metadata.name }},
    @{Name='Phase'; Expression={ $_.status.phase }}
```

Confirm that the deleted pod has been replaced and that two web replicas are ready.
Restart the web port forward if it disconnected, then check the web page again.
If replacement fails, inspect events and quota rather than assuming recovery.

Return the lab to one web replica after the exercise:

```powershell
kubectl scale deployment $env:LAB_WEB_NAME --namespace $env:LAB_NAMESPACE --replicas=1
kubectl rollout status "deployment/$($env:LAB_WEB_NAME)" --namespace $env:LAB_NAMESPACE --timeout=10m
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

[Next: modernize Caldova from source]({{ site.baseurl }}{% link appmod-lab/6-caldova-source-modernization/index.md %}) |
[Workshop home]({{ site.baseurl }}{% link index.md %})
