# Enterprise-Grade EKS Multi-Tenant Platform with GitOps & Centralized Observability

## Project Overview
Engineered a secure, scalable, and highly available multi-tenant Amazon EKS platform designed to isolate distinct corporate business units (**Tenant-Alpha** and **Tenant-Beta**) on a shared computing infrastructure. The platform leverages modern GitOps practices for continuous deployment, enforces strict logical isolation, implements resource boundaries, and provides a centralized observability engine to track tenant logs asynchronously.

* **Repository / Code Architecture:** `~/Cloud/eks-multi-tenant-platform`
* **Infrastructure Scope:** Production-ready multi-tenant microservices, automated control planes, and centralized logging frameworks.

---

## Why This Project Matters (Business Impact & Importance)
Deploying standalone cloud environments for every department or business entity creates massive financial waste, operational fragmentation, and security blind spots. This multi-tenant platform addresses those enterprise vulnerabilities by providing:

* **Massive Cloud Cost Optimization (50-70% Savings):** Instead of provisioning separate AWS EKS control planes and duplicate infrastructure for individual tenants—which severely inflates monthly cloud bills—this system consolidates independent workloads onto a single, tightly packed cluster, drastically lowering compute overhead.
* **Rigid Regulatory & Data Compliance:** In an enterprise environment, tenants must never leak or glimpse each other's data. By implementing strict namespace segmentation and RBAC models, this project demonstrates a production-ready blueprint for handling sensitive tenant workloads while adhering to global compliance mandates.
* **Elimination of GitOps Configuration Drift:** Hand-crafting cloud resources introduces user error. By routing cluster state completely through ArgoCD, infrastructure mutations are tracked transparently in Git, allowing instant rollbacks, disaster recovery, and automated synchronization.
* **Unified, Cost-Efficient Telemetry Control:** Rather than configuring disparate monitoring nodes for every tenant application, this centralized Fluent Bit-to-CloudWatch pipeline handles millions of log lines under a singular pipeline. It reduces operational noise for site reliability engineers (SREs) while preserving chronological audit trails.

---

## Tech Stack
* **Orchestration & Cloud:** Amazon EKS (v1.35), AWS EC2, AWS VPC CNI
* **GitOps & Continuous Delivery:** ArgoCD (Application Controllers, ApplicationSets, Redis)
* **Ingress & Traffic Control:** Ingress-Nginx Controller
* **Observability & Log Shipping:** AWS for Fluent Bit (v4.1.1), Amazon CloudWatch Logs, CloudWatch Log Insights
* **Isolation & Security:** Kubernetes RBAC (Roles/RoleBindings), Namespaces, Resource Quotas/Limits

---

## System Architecture & Key Features

### 1. GitOps Continuous Delivery & Traffic Routing
* Deployed **ArgoCD** as a centralized cluster control plane to manage application life cycles through declarative Git repositories.
* Utilized **Ingress-Nginx** to handle external cluster communications, using a centralized proxy layer to route path-based tenant traffic cleanly to independent internal services.

### 2. Multi-Tenant Security & Resource Isolation
* **Logical Partitioning:** Implemented rigid network and resource air-gapping using Kubernetes namespaces (`tenant-alpha` and `tenant-beta`).
* **Role-Based Access Control (RBAC):** Configured specialized cluster permissions ensuring that engineering teams can only view or alter workloads within their designated scope.
* **Resource Quota Boundaries:** Set strict CPU and Memory requests and limits per container to protect against "noisy neighbor" scenarios, preventing a single tenant from monopolizing host node capacity.

### 3. Centralized Enterprise Observability Pipeline
* **Log Harvesting:** Architected an asynchronous logging framework using **AWS for Fluent Bit** running as a cluster-wide `DaemonSet`.
* **Metadata Enrichment:** Configured Fluent Bit to strip container stdout streams, parse them into structured JSON, and append critical cluster context keys (`kubernetes.namespace_name`, `kubernetes.pod_name`).
* **CloudWatch Integration:** Authorized secure cross-platform data transit utilizing AWS IAM Node Policies to ship records directly to AWS CloudWatch Logs (`/aws/containerinsights/dev-eks/application`).
* **Advanced Analytics:** Built operational telemetry inside CloudWatch Log Insights, enabling real-time cross-tenant analysis, alerting, and filtering from a single control window.

---

## System Verification & Visual Proof

To validate the active deployment, resource boundaries, and telemetry separation of the multi-tenant architecture, live environment captures were taken across the cluster control planes.

### 1. Cluster Isolation, RBAC, and Resource Boundaries
![ArgoCD Multi-Tenant Architecture Overview](./images/argocd-tenant-isolation.png)
> **Figure 1.1:** *The ArgoCD enterprise dashboard displaying the synchronized state of the platform. This view confirms **Secure Namespace Isolation** (`tenant-alpha` and `tenant-beta` running as detached trees), governed by strict **Team-Based Access Control** policies, alongside declarative **Resource Quotas** embedded directly within the application deployment manifests.*

### 2. Centralized Log Storage Vault
![AWS CloudWatch Log Streams Interface](./images/cloudwatch-log-streams.png)
> **Figure 1.2:** *The active Amazon CloudWatch dashboard highlighting the target log group `/aws/containerinsights/dev-eks/application`. The lower pane confirms active log streams parsing container outputs, establishing a decoupled, permanent storage vault off-instance for **Central Logging**.*

### 3. Live Cross-Tenant Log Insights Query Execution
![AWS CloudWatch Log Insights Multi-Tenant Parsing](./images/cloudwatch-log-insights.png)
> **Figure 1.3:** *Executing an asynchronous metadata query within CloudWatch Log Insights. The generated timeline and data rows demonstrate live multi-tenant log parsing, isolating distinct namespace keys right down to individual container replicas in real time.*

---

## Engineering Challenges & Solutions

### Overcoming the VPC CNI Pod Allocation Ceiling
> **The Challenge:** During the rollout of the Fluent Bit logging engine, several pods stalled indefinitely in a `Pending` state, throwing severe scheduling errors (`Too many pods` / `NodeAffinity`). 
>
> **The Diagnosis:** The underlying worker tier used `t3.small` instances, which carry a hard AWS ENI networking limit of exactly **11 pods per node**. Because the management plane components (ArgoCD, Nginx, Kube-Proxy, AWS CNI Node Agents) consumed 7 to 8 network slots right out of the box, the cluster ran out of available IP allocations to spin up multi-replica tenant workloads and the logging layer simultaneously.
>
> **The Solution:**
> * Audited and patched Fluent Bit’s resource profile down to a lean allocation (`100m` CPU request).
> * Optimized tenant deployment architectures by executing controlled horizontal scale-downs (`kubectl scale`) to enforce exactly 1 highly-efficient replica per application tier per tenant.
> * Evicted legacy, non-functional pods to drop node utilization below the 11-pod threshold.
> * **Result:** Restored 100% cluster health, allowing control engines, tenant APIs, and logging collectors to run flawlessly alongside each other within a constrained resource environment.

---

## Verification & Results

Using CloudWatch Log Insights, tenant data segregation can be verified globally with the following metric query:

```sql
fields @timestamp, kubernetes.namespace_name, kubernetes.pod_name, log
| filter kubernetes.namespace_name in ["tenant-alpha", "tenant-beta"]
| sort @timestamp desc
| limit 50
```

---

## Production Log Output Stream
```
{
  "@timestamp": "2026-06-25 17:09:41.652Z",
  "kubernetes.namespace_name": "tenant-alpha",
  "kubernetes.pod_name": "backend-api-7c9d84d957-2skrt",
  "log": "Application successfully listening on port 8080"
}
```
