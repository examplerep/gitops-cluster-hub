# GitOps Cluster Hub

GitOps configuration for the Example Power hub cluster.

## Overview

This repository contains:

- Ansible playbooks for bootstrapping GitOps on the hub cluster
- ArgoCD Application definitions for cluster configuration
- Cluster-wide configurations managed via GitOps

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

Installs OpenShift GitOps operator on the hub cluster.

```shell
# First, login to the hub cluster
oc login https://api.hub.ocp.examplerep.com:6443 -u kubeadmin -p <password>

# Run the bootstrap playbook
source .venv/bin/activate
cd ansible
ansible-playbook playbooks/bootstrap-gitops.yml
```

**What it does:**

1. Creates the openshift-gitops-operator namespace
2. Installs the OpenShift GitOps operator via OLM
3. Waits for the operator and ArgoCD instance to be ready
4. Outputs ArgoCD access credentials

## Directory Structure

```text
ansible/
├── ansible.cfg                 # Ansible configuration
├── inventory/
│   └── hosts.yml               # Inventory configuration
├── playbooks/
│   └── bootstrap-gitops.yml    # GitOps bootstrap playbook
└── requirements.txt            # Python dependencies
README.md                       # This file
```
