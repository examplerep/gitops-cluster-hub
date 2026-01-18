# GitOps Cluster Hub

GitOps configuration for the Example Power hub cluster.

## Overview

This repository contains:

- Ansible playbooks for bootstrapping GitOps on the hub cluster
- ArgoCD Application definitions for cluster configuration
- Operator subscriptions managed via GitOps

## Operators Managed

| Operator                  | Namespace                  | Source            |
| ------------------------- | -------------------------- | ----------------- |
| OpenShift GitOps          | openshift-gitops-operator  | redhat-operators  |
| OpenShift Pipelines       | openshift-operators        | redhat-operators  |
| OpenShift Cert Manager    | cert-manager-operator      | redhat-operators  |
| External Secrets Operator | external-secrets           | community-operators |
| Red Hat Developer Hub     | rhdh-operator              | redhat-operators  |

## Prerequisites

- Access to the hub cluster (`oc login` completed)
- Python 3.9+

## Setup

```shell
cd ansible
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Playbooks

### Bootstrap GitOps

Installs OpenShift GitOps operator and creates the ArgoCD Application to manage all operators.

```shell
# First, login to the hub cluster
oc login https://api.hub.ocp.examplerep.com:6443 -u kubeadmin -p <password>

# Run the bootstrap playbook
cd ansible
source .venv/bin/activate
ansible-playbook playbooks/bootstrap-gitops.yml
```

**What it does:**

1. Applies OpenShift GitOps operator manifests
2. Waits for the operator and ArgoCD instance to be ready
3. Creates ArgoCD Application to manage all hub operators
4. Outputs ArgoCD access credentials

## Directory Structure

```text
ansible/
├── ansible.cfg                    # Ansible configuration
├── inventory/
│   └── hosts.yml                  # Inventory configuration
├── playbooks/
│   └── bootstrap-gitops.yml       # GitOps bootstrap playbook
└── requirements.txt               # Python dependencies
manifests/
├── argocd-apps/
│   ├── hub-operators.yaml         # ArgoCD Application for operators
│   └── kustomization.yaml
└── operators/
    ├── cert-manager/              # Cert Manager operator
    ├── developer-hub/             # Red Hat Developer Hub operator
    ├── external-secrets/          # External Secrets operator
    ├── openshift-gitops/          # OpenShift GitOps operator
    ├── openshift-pipelines/       # OpenShift Pipelines operator
    └── kustomization.yaml
README.md                          # This file
```

## GitOps Flow

```text
┌─────────────────────────────────────────────────────────────┐
│                    Bootstrap Playbook                        │
│                                                             │
│  1. Apply OpenShift GitOps operator                         │
│  2. Wait for ArgoCD                                         │
│  3. Create hub-operators Application                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      ArgoCD                                  │
│                                                             │
│  hub-operators Application                                  │
│    └── Syncs manifests/operators/                           │
│        ├── openshift-gitops                                 │
│        ├── openshift-pipelines                              │
│        ├── cert-manager                                     │
│        ├── external-secrets                                 │
│        └── developer-hub                                    │
└─────────────────────────────────────────────────────────────┘
```
