#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '%s %s\n' "$(date '+%F %T')" "$*"
}

cd "$(dirname "${BASH_SOURCE[0]}")"

command -v oc >/dev/null 2>&1 || { log "ERROR: `oc` command not found"; exit 1; }
oc whoami >/dev/null 2>&1 || { log "ERROR: User not logged in to a cluster"; exit 1; }

log "Applying openshift-gitops-operator"
oc apply -k openshift-gitops-operator

log "Waiting for OpenShift GitOps operator install (CSV phase Succeeded)..."
start_ts=$SECONDS
while true; do
  phase=$(oc get csv -n openshift-gitops-operator -o jsonpath='{.items[0].status.phase}' 2>/dev/null || true)
  if [[ "$phase" == "Succeeded" ]]; then
    break
  fi
  if [[ "$phase" == "Failed" ]]; then
    log "ERROR: ClusterServiceVersion install failed"
    oc get csv -n openshift-gitops-operator -o wide >&2 || true
    exit 1
  fi
  if (( SECONDS - start_ts >= 900 )); then
    log "ERROR: Timed out after 15m waiting for operator CSV"
    oc get subscription,csv -n openshift-gitops-operator >&2 || true
    exit 1
  fi
  sleep 5
done

log "OpenShift GitOps operator is ready"

log "Applying openshift-gitops-cluster"
oc apply -k openshift-gitops-cluster

log "Waiting for Argo CD instance cluster-argocd (status.phase Available)..."
start_ts=$SECONDS
while true; do
  phase=$(oc get argocd cluster-argocd -n openshift-gitops-cluster -o jsonpath='{.status.phase}' 2>/dev/null || true)
  if [[ "$phase" == "Available" ]]; then
    break
  fi
  if [[ "$phase" == "Failed" ]]; then
    log "ERROR: ArgoCD instance failed"
    oc get argocd -n openshift-gitops-cluster -o yaml >&2 || true
    exit 1
  fi
  if (( SECONDS - start_ts >= 1200 )); then
    log "ERROR: Timed out after 20m waiting for Argo CD"
    oc get argocd,pods -n openshift-gitops-cluster >&2 || true
    exit 1
  fi
  sleep 5
done

log "Cluster Argo CD instance is ready"
