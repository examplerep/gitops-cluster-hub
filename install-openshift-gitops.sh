#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check prerequisites
check_prerequisites() {
    info "Checking prerequisites..."

    if ! command -v oc &> /dev/null; then
        error "oc CLI is not installed. Please install the OpenShift CLI."
    fi

    if ! oc whoami &> /dev/null; then
        error "Not logged in to an OpenShift cluster. Please run 'oc login' first."
    fi

    info "Logged in as: $(oc whoami)"
    info "Cluster: $(oc whoami --show-server)"
}

# Apply OpenShift GitOps manifests
apply_manifests() {
    info "Applying OpenShift GitOps manifests..."

    # Apply manifests in order respecting sync-waves
    oc apply -f "$SCRIPT_DIR/openshift-gitops/namespace.yaml"
    oc apply -f "$SCRIPT_DIR/openshift-gitops/operatorgroup.yaml"
    oc apply -f "$SCRIPT_DIR/openshift-gitops/subscription.yaml"
}

# Wait for operator to be installed
wait_for_operator() {
    info "Waiting for OpenShift GitOps operator to be installed..."

    local timeout=300
    local interval=10
    local elapsed=0

    while [ $elapsed -lt $timeout ]; do
        # Check if the CSV is in Succeeded phase
        csv_status=$(oc get csv -n openshift-gitops -o jsonpath='{.items[?(@.spec.displayName=="Red Hat OpenShift GitOps")].status.phase}' 2>/dev/null || echo "")

        if [ "$csv_status" == "Succeeded" ]; then
            info "OpenShift GitOps operator installed successfully!"
            return 0
        fi

        echo -n "."
        sleep $interval
        elapsed=$((elapsed + interval))
    done

    echo ""
    error "Timeout waiting for OpenShift GitOps operator to install. Current status: $csv_status"
}

# Wait for default ArgoCD instance to be ready
wait_for_argocd() {
    info "Waiting for ArgoCD instance to be ready..."

    local timeout=300
    local interval=10
    local elapsed=0

    while [ $elapsed -lt $timeout ]; do
        # Check if the ArgoCD server deployment is available
        ready=$(oc get deployment openshift-gitops-server -n openshift-gitops -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo "0")

        if [ "$ready" != "" ] && [ "$ready" -ge 1 ]; then
            info "ArgoCD is ready!"
            return 0
        fi

        echo -n "."
        sleep $interval
        elapsed=$((elapsed + interval))
    done

    echo ""
    warn "Timeout waiting for ArgoCD to be ready. It may still be starting up."
}

# Apply custom ArgoCD configuration
apply_argocd_config() {
    info "Applying custom ArgoCD configuration..."
    oc apply -f "$SCRIPT_DIR/openshift-gitops/argocd.yaml"
}

# Get ArgoCD route
get_argocd_route() {
    info "Getting ArgoCD server route..."

    local route
    route=$(oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}' 2>/dev/null || echo "")

    if [ -n "$route" ]; then
        info "ArgoCD URL: https://$route"
    else
        warn "Could not retrieve ArgoCD route. It may not be ready yet."
    fi
}

# Main installation
main() {
    echo ""
    echo "=========================================="
    echo "  OpenShift GitOps Installation Script"
    echo "=========================================="
    echo ""

    check_prerequisites
    apply_manifests
    wait_for_operator
    wait_for_argocd
    apply_argocd_config
    get_argocd_route

    echo ""
    info "Installation complete!"
    info "You can log in to ArgoCD using your OpenShift credentials via the OpenShift OAuth integration."
    echo ""
}

main "$@"
