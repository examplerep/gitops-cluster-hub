# GitOps Cluster Hub

Bootstrap and manage OpenShift GitOps (ArgoCD) using an app-of-apps pattern.

## Structure

```
gitops-cluster-hub/
├── install-openshift-gitops.sh   # Bash script to bootstrap GitOps
├── app-of-apps.yaml              # Root Application that manages all apps
├── applications/                 # ArgoCD Applications
│   ├── kustomization.yaml
│   ├── project-cluster.yaml
│   ├── openshift-gitops.yaml
│   └── openshift-external-secrets.yaml
├── openshift-gitops/             # OpenShift GitOps operator manifests
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   ├── operator-group.yaml
│   ├── cluster-admin-rbac.yaml
│   ├── subscription.yaml
│   └── argocd.yaml
└── openshift-external-secrets/   # External Secrets operator manifests
    ├── kustomization.yaml
    ├── namespace.yaml
    ├── operator-group.yaml
    ├── subscription.yaml
    ├── cluster-secret-store.yaml
    └── external-secret-test.yaml
```

## Prerequisites

- OpenShift cluster with cluster-admin access
- `oc` CLI installed and logged into the cluster
- AWS credentials with access to Secrets Manager (for External Secrets)

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

### Step 2: Create AWS Secrets Manager Credentials

Before deploying the app-of-apps, create the AWS credentials secret for External Secrets:

```bash
oc create namespace openshift-external-secrets

oc create secret generic aws-secrets-manager-credentials \
  -n openshift-external-secrets \
  --from-literal=access-key-id=$(aws configure get aws_access_key_id) \
  --from-literal=secret-access-key=$(aws configure get aws_secret_access_key)
```

The AWS IAM user/role needs the following permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:ListSecrets"
      ],
      "Resource": "*"
    }
  ]
}
```

### Step 3: Deploy the App-of-Apps

Once OpenShift GitOps is running and the AWS credentials are in place, deploy the app-of-apps:

```bash
oc apply -f app-of-apps.yaml
```

The app-of-apps will automatically sync and deploy all applications defined in the `applications/` directory.

## Validating External Secrets

A test ExternalSecret is included to validate the ClusterSecretStore configuration. First, create a test secret in AWS Secrets Manager:

```bash
aws secretsmanager create-secret \
  --name foo \
  --secret-string "bar"
```

After the app-of-apps syncs, verify the secret was created in Kubernetes:

```bash
oc get secret test-secret -n openshift-external-secrets -o jsonpath='{.data.foo}' | base64 -d
```

This should return `bar`.

## Using External Secrets

### Creating Secrets in AWS Secrets Manager

Create a simple string secret:

```bash
aws secretsmanager create-secret \
  --name my-secret \
  --secret-string "my-secret-value"
```

Update an existing secret:

```bash
aws secretsmanager put-secret-value \
  --secret-id my-secret \
  --secret-string "my-new-secret-value"
```

Create a JSON secret with multiple key/value pairs:

```bash
aws secretsmanager create-secret \
  --name my-app-secrets \
  --secret-string '{"username":"admin","password":"s3cr3t"}'
```

### Syncing Secrets to Kubernetes

Once the External Secrets operator and ClusterSecretStore are deployed, create ExternalSecret resources to sync secrets from AWS Secrets Manager.

**Example 1: Simple string secret**

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-secret
  namespace: my-namespace
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: my-secret
    creationPolicy: Owner
  dataFrom:
    - extract:
        key: my-secret
```

**Example 2: JSON secret with specific keys**

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-app-secrets
  namespace: my-namespace
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: my-app-secrets
    creationPolicy: Owner
  data:
    - secretKey: username
      remoteRef:
        key: my-app-secrets
        property: username
    - secretKey: password
      remoteRef:
        key: my-app-secrets
        property: password
```

## Adding Applications

Add new ArgoCD Applications to `applications/` and update `applications/kustomization.yaml`:

```yaml
resources:
  - project-cluster.yaml
  - openshift-gitops.yaml
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
