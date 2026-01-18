# GitOps Cluster Hub

Bootstrap and manage OpenShift GitOps (ArgoCD) using an app-of-apps pattern.

## Structure

```
gitops-cluster-hub/
├── bootstrap-gitops.yml        # Ansible playbook to bootstrap GitOps
├── app-of-apps.yaml            # Root Application that manages all apps
├── applications/               # ArgoCD Applications
│   ├── kustomization.yaml
│   └── openshift-gitops.yaml   # Application for GitOps operator config
└── openshift-gitops/           # OpenShift GitOps operator manifests
    ├── kustomization.yaml
    ├── namespace.yaml          # sync-wave: 0
    ├── operatorgroup.yaml      # sync-wave: -2
    ├── subscription.yaml       # sync-wave: -1
    └── argocd.yaml             # sync-wave: 0 (custom health checks)
```

## Prerequisites

- OpenShift cluster with cluster-admin access
- Ansible with `kubernetes.core` collection installed
- `oc` CLI logged into the cluster

## Bootstrap

Run the Ansible playbook to install OpenShift GitOps and create the app-of-apps:

```bash
ansible-playbook bootstrap-gitops.yml
```

This will:
1. Create the `openshift-gitops` namespace
2. Install the OpenShift GitOps operator
3. Configure the ArgoCD instance with custom health checks
4. Create the app-of-apps Application to manage all other Applications

## Adding Applications

Add new ArgoCD Applications to `applications/` and update `applications/kustomization.yaml`:

```yaml
resources:
  - openshift-gitops.yaml
  - my-new-app.yaml
```

The app-of-apps will automatically sync and deploy your new Application.

## Custom Health Checks

Custom health checks are defined in `openshift-gitops/argocd.yaml` under `spec.resourceCustomizations`. Current health checks:

- `operators.coreos.com/Subscription`
- `operators.coreos.com/InstallPlan`

To add more, append to the `resourceCustomizations` field:

```yaml
your.group.io/YourCRD:
  health.lua: |
    hs = {}
    -- Lua health check logic
    return hs
```
