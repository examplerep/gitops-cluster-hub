# GitOps Cluster Hub

Bootstrap and manage OpenShift GitOps (ArgoCD) using an app-of-apps pattern.

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

### Step 3: Deploy the App-of-Apps

Once OpenShift GitOps is running and the AWS credentials are in place, deploy the app-of-apps:

```bash
oc apply -f app-of-apps.yaml
```

The app-of-apps will automatically sync and deploy all applications defined in the `applications/` directory.
