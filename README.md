# GitOps Cluster Hub

Bootstrap and manage OpenShift GitOps (ArgoCD) using an app-of-apps pattern.

## Structure

```
gitops-cluster-hub/
├── install-openshift-gitops.sh # Bash script to bootstrap GitOps
├── app-of-apps.yaml            # Root Application that manages all apps
├── applications/               # ArgoCD Applications
│   ├── kustomization.yaml
│   ├── openshift-gitops.yaml
│   ├── openshift-cert-manager.yaml
│   └── openshift-external-secrets.yaml
├── openshift-gitops/           # OpenShift GitOps operator manifests
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   ├── operatorgroup.yaml
│   ├── subscription.yaml
│   └── argocd.yaml
├── openshift-cert-manager/     # Cert Manager operator manifests
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   ├── operatorgroup.yaml
│   └── subscription.yaml
└── openshift-external-secrets/ # External Secrets operator manifests
    ├── kustomization.yaml
    ├── namespace.yaml
    ├── operatorgroup.yaml
    └── subscription.yaml
```

## Prerequisites

- OpenShift cluster with cluster-admin access
- `oc` CLI installed and logged into the cluster

## Bootstrap

### Step 1: Install OpenShift GitOps

Run the installation script to install the OpenShift GitOps operator:

```bash
./install-openshift-gitops.sh
```

This will:
1. Create the `openshift-gitops` namespace
2. Create the OperatorGroup
3. Install the OpenShift GitOps operator via Subscription
4. Wait for the operator to be ready
5. Wait for the ArgoCD instance to be available
6. Display the ArgoCD URL

### Step 2: Deploy the App-of-Apps

Once OpenShift GitOps is running, deploy the app-of-apps to manage all applications:

```bash
oc apply -f app-of-apps.yaml
```

The app-of-apps will automatically sync and deploy all applications defined in the `applications/` directory.

## Adding Applications

Add new ArgoCD Applications to `applications/` and update `applications/kustomization.yaml`:

```yaml
resources:
  - openshift-gitops.yaml
  - openshift-cert-manager.yaml
  - openshift-external-secrets.yaml
  - my-new-app.yaml
```

The app-of-apps will automatically sync and deploy your new Application.

## Custom Health Checks

Custom health checks are defined in `openshift-gitops/argocd.yaml` under `spec.resourceCustomizations`. Current health checks:

- `operators.coreos.com/Subscription` - Reports healthy when state is `AtLatestKnown`
- `operators.coreos.com/InstallPlan` - Reports healthy when phase is `Complete`

To add more, append to the `resourceCustomizations` field:

```yaml
your.group.io/YourCRD:
  health.lua: |
    hs = {}
    -- Lua health check logic
    return hs
```

## Accessing ArgoCD

After installation, access the ArgoCD UI:

```bash
# Get the ArgoCD route
oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}'
```

Log in using your OpenShift credentials via the built-in OAuth integration.
