# Internal Developer Platform (IDP) Core Infrastructure

A production-grade, cloud-native Internal Developer Platform (IDP) architecture deployed on **AWS EKS** utilizing **Infrastructure-as-Code**, **GitOps principles with ArgoCD**, and automated **CI pipelines**. This platform streamlines microservice delivery, abstracting underlying infrastructure complexities to enable automated, zero-downtime application deployment workflows.

---

## 💡 Project Importance

In modern software engineering, developers often lose hours managing infrastructure, configuring ingress routes, or setting up deployment pipelines instead of writing features. This **Internal Developer Platform (IDP)** solves that problem by implementing **Platform Engineering** principles. 

* **True GitOps & Security Isolation:** By utilizing **ArgoCD**, the Kubernetes cluster pulls configurations directly from Git. Your external pipeline never needs admin-level cluster keys, significantly minimizing your infrastructure's attack surface.
* **Developer Self-Service:** It abstracts away complex AWS and Kubernetes configurations, allowing engineering teams to ship code safely with a simple `git push`.
* **Enterprise-Grade Reliability:** Eliminates configuration drift completely. ArgoCD constantly monitors the cluster, ensuring that manual, rogue changes are automatically self-healed back to the Git source of truth.
* **Cost & Asset Efficiency:** Centralizing microservices under a unified Ingress controller reduces cloud spend by maximizing cluster resource utilization and avoiding single-load-balancer sprawl.

---

## Tools Used

The platform was engineered using an industry-standard, cloud-native technology matrix:

* **Cloud Infrastructure:** AWS EKS (Elastic Kubernetes Service), Amazon ECR (Elastic Container Registry), AWS IAM (Identity & Access Management).
* **GitOps & Delivery Engine:** ArgoCD (Declarative Continuous Delivery Engine).
* **Containerization & Orchestration:** Docker Engine, Kubernetes API (Deployments, Services, Namespaces).
* **Traffic & Networking:** NGINX Ingress Controller, AWS Native Network/Application Load Balancers.
* **CI Automation:** GitHub Actions (Automated Runner Environments).
* **Application Layer:** Node.js (Stateless native HTTP runtime architecture).
* **Operating Environment:** WSL2 Ubuntu Linux / Linux Bash Shell.

---

## System Architecture & Traffic Flow

The platform separates continuous integration (CI) from continuous deployment (CD) via a pull-based architecture:
```markdown
```text
[ Developer Push ] ──► [ GitHub Actions (CI) ] ──► [ Builds & Pushes Image to Amazon ECR ]
                                                                   │
                                                                   ▼
[ Live AWS EKS Cluster ] ◄── [ ArgoCD (CD Engine) ] ◄── [ Watches Git Manifest Repository ]
           │
     (Ingress Routing)
     
[ Public Traffic ] ──► [ AWS Load Balancer ] ──► [ NGINX Ingress ] ──► [ LoadBalancer Service ] ──► [ Pod Mesh ]

```

---

## How We Built It

The architecture was designed and executed over four distinct core execution phases:

1. **Workload Containerization:** We encapsulated the stateless Node.js application inside an optimized Docker image layer, establishing strict internal port configurations (`8080`) to guarantee ambient execution parity between local and cloud environments.
2. **EKS Clusters and Internal Networking:** We provisioned high-availability resources on **AWS EKS** under a dedicated application namespace (`apps`). We then mapped a multi-replica `Deployment` behind an active `LoadBalancer` Service layer to interface cleanly with our external traffic ingress tools.
3. **Edge Ingress Engineering:** To bridge public internet traffic to the cluster mesh, we deployed an **NGINX Ingress Controller**. We optimized the ingress routing parameters to use an efficient `Prefix` path configuration (`/api`), clearing out $404$ routing validation errors by making the edge gateway fully path-agnostic.
4. **ArgoCD GitOps Declaration:** We bootstrapped **ArgoCD** inside our EKS cluster and wired it to our repository. Instead of pushing direct mutations via CLI, our **GitHub Actions** workflow builds your container, handles image registry shipping to **Amazon ECR**, and updates your manifest definitions, allowing ArgoCD to pull and synchronize the state autonomously.

---

## What We Achieved

* **Declarative Continuous Delivery:** Achieved 100% automated software delivery pipelines. Developers only push to `main`, while GitHub Actions packages the artifact, and ArgoCD orchestrates the cloud state synchronization natively.
* **Zero-Drift Enforcement:** Implemented strict cluster self-healing loops. If an engineer manually alters a cloud resource using a raw terminal, ArgoCD flags the drift and instantly auto-corrects the cluster to match Git.
* **Zero-Downtime Rolling Updates:** Engineered a platform capable of substituting application pod replicas on-the-fly, ensuring the public API endpoint remains fully available with zero performance degradation during updates.
* **Enterprise Security Hygiene:** Successfully decoupled CI secrets from the cluster environment, entirely dropping the requirement of storing persistent master deployment tokens outside of AWS.

---

##  Platform Component Blueprint

| Infrastructure Component | Underpinned Technology | Access / Security Layer | Operational Delivery Strategy |
| --- | --- | --- | --- |
| **Application Layer** | Node.js Core API | Container-Internal Port `8080` | Stateless Microservice |
| **Container Registry** | Amazon ECR | AWS IAM Access Control | Automated Image Version Tagging |
| **GitOps Controller** | ArgoCD | Cluster-Internal Pull Loop | Automated Target State Reconciliation |
| **Cluster Orchestration** | AWS EKS (`dev-eks`) | Kubeconfig Token Injection | Multi-Replica Rolling Deployment via **LoadBalancer Service** |
| **Ingress Gatekeeper** | NGINX Ingress Controller | AWS Edge Infrastructure Load Balancer | Prefix Path Match (`/api`) |
| **CI Automation Engine** | GitHub Actions | Repository Action Secrets | Remote Image Pushes to ECR |

---

## Step-by-Step Production Deployment Flow

### 1. Automated GitHub Actions Core Configuration (CI Only)

The automation engine runs a high-performance script on every code commit to `main`, preparing your runtime build before passing deployment custody off to ArgoCD:

```yaml
name: CI Pipeline - Build & Push to ECR

on:
  push:
    branches:
      - main

jobs:
  build-and-push:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout Code
      uses: actions/checkout@v4

    - name: Configure AWS Credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-1

    - name: Log in to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v2

    - name: Build, Tag, and Push Image to ECR
      env:
        ECR_REGISTRY: 763054201983.dkr.ecr.us-east-1.amazonaws.com
        ECR_REPOSITORY: backend-api
        IMAGE_TAG: latest
      working-directory: ./src/backend
      run: |
        docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG

```

### 2. ArgoCD Application Manifest Setup (`application.yaml`)

To instruct ArgoCD to sync your platform declarations with your cluster, the following configuration pattern is managed inside the Git system:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: backend-api-platform
  namespace: argocd
spec:
  project: default
  source:
    repoURL: '[https://github.com/your-username/internal-developer-platform.git](https://github.com/your-username/internal-developer-platform.git)'
    targetRevision: HEAD
    path: infrastructure/manifests
  destination:
    server: '[https://kubernetes.default.svc](https://kubernetes.default.svc)'
    namespace: apps
  syncPolicy:
    automated:
      prune: true
      selfHeal: true

```

### 3. Edge Networking Traffic Route Manifest (`backend-api-ingress.yaml`)

To abstract internal target architectures from public calls, the platform uses an optimized ingress rule set:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: backend-api-ingress
  namespace: apps
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-api-service
            port:
              number: 80

```

---

## Architectural Visual Evidence

This section documents the live validation states of the platform's cloud infrastructure, automated pipelines, GitOps sync state, and recovery tools.

### 1. Automated CI Pipeline Success (GitHub Actions)

```markdown
![GitHub Actions Workflow Run](screenshots/github-actions.png)

```

> **Figure 1:** Successful execution of the GitHub Actions CI workflow engine. This confirms flawless code checkout, secure AWS ECR container image generation, and successful remote image compilation.

### 2. GitOps Synchronization State (ArgoCD UI Main Dashboard)

```markdown
![ArgoCD Deployment Synchronized Dashboard](screenshots/argocd-dashboard.png)

```

> **Figure 2:** ArgoCD graphical interface tracking the overall topology of the `backend-api-platform` application. This confirms that all declared manifests match the active cloud configuration.

### 3. Comprehensive Manifest Sync Health & Resource Tree

```markdown
![ArgoCD Resource Health Tree](screenshots/argocd-health.png)

```

> **Figure 3:** Detailed health status tree in ArgoCD showing the green `Synced` and `Healthy` statuses across all subordinate resources—including the Deployment, LoadBalancer Service, Ingress controller, and underlying Pod replicas.

### 4. GitOps Rollback & History Panel

```markdown
![ArgoCD Rollback and History Panel](screenshots/argocd-rollback.png)

```

> **Figure 4:** The "History and Rollback" interface inside ArgoCD. This visual panel displays previous deployment revisions, tracking individual Git commit tags and proving the ability to trigger a sub-second rollout reversion with a single click.

### 5. High-Availability Cluster Orchestration (Kubernetes CLI)

```markdown
![Kubernetes Resources Status](screenshots/kubectl-status.png)

```

> **Figure 5:** Output of `kubectl get all -n apps` run via the terminal. Visual validation confirms that the multi-replica `Deployment` is healthy, multiple isolated backend `Pods` are actively running in a balanced state, and the **LoadBalancer Service layer** is properly bound to port `80`, mapping directly to your AWS cloud infrastructure.

### 6. Edge Gate Traffic Isolation (NGINX Ingress Resource)

```markdown
![Kubernetes Ingress Controller Output](screenshots/kubectl-ingress.png)

```

> **Figure 6:** Terminal log capturing `kubectl get ingress -n apps`. This displays the `backend-api-ingress` asset properly bound to the NGINX `ingressClassName`, mapping traffic to the public AWS Load Balancer endpoint IP.

### 7. Verified Live Production API Endpoint

```markdown
![Live Browser API Response](screenshots/browser-api.png)

```

> **Figure 7:** Browser output hitting the public AWS Ingress gateway address at `/api/`. This showcases the successful raw JSON server payload returning the active environment parameters (`production-eks`) and live version tracking strings updated via the automated pipeline.

---

## Platform Management Runbook

### Executing Instant Rollbacks via GitOps

If a faulty image or manifest change is deployed, you retain standard Git auditing history. Rather than writing ad-hoc terminal patches, rollbacks are handled through standard revert parameters:

```bash
# Revert your repository state back to the previous Git commit configuration
git revert HEAD --no-edit

# Push change to trigger ArgoCD to automatically step back the cluster deployment version
git push origin main

```

*Alternatively, if emergency intervention is required, rollbacks can be executed with a single click via the **ArgoCD Dashboard UI** or by running the ArgoCD CLI tool:*

```bash
argocd app rollback backend-api-platform

```

```***

```
