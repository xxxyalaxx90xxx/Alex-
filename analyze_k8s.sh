#!/usr/bin/env bash
set -euo pipefail

# Kubernetes Cluster Data Analysis Script
# Analyzes the current Kubernetes cluster setup and generates a detailed report

KUBECONFIG_FILE=${KUBECONFIG_FILE:-$HOME/.kube/config}
OUTPUT_FILE=${OUTPUT_FILE:-k8s_analysis_report.txt}

echo "=== Kubernetes Cluster Data Analysis ===" | tee "${OUTPUT_FILE}"
echo "Timestamp: $(date)" | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

# Check if kubectl is available
if ! command -v kubectl >/dev/null 2>&1; then
  echo "ERROR: kubectl is not installed or not in PATH" | tee -a "${OUTPUT_FILE}"
  exit 1
fi

# Check if kubeconfig exists
if [ ! -f "${KUBECONFIG_FILE}" ]; then
  echo "ERROR: kubeconfig file not found at ${KUBECONFIG_FILE}" | tee -a "${OUTPUT_FILE}"
  exit 1
fi

export KUBECONFIG="${KUBECONFIG_FILE}"

echo "=== 1. Cluster Information ===" | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

# Cluster version
echo "Kubernetes Version:" | tee -a "${OUTPUT_FILE}"
kubectl version --short 2>/dev/null | tee -a "${OUTPUT_FILE}" || kubectl version 2>/dev/null | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

# Cluster info
echo "Cluster Info:" | tee -a "${OUTPUT_FILE}"
kubectl cluster-info 2>/dev/null | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

echo "=== 2. Node Analysis ===" | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

# Node status
echo "Node Status:" | tee -a "${OUTPUT_FILE}"
kubectl get nodes -o wide 2>/dev/null | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

# Node resource details
echo "Node Resource Allocation:" | tee -a "${OUTPUT_FILE}"
kubectl top nodes 2>/dev/null | tee -a "${OUTPUT_FILE}" || echo "Metrics server not available for resource metrics" | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

# Hugepages information
echo "Hugepages Configuration:" | tee -a "${OUTPUT_FILE}"
kubectl get nodes -o yaml 2>/dev/null | grep -E "hugepages-|capacity:|allocatable:" | tee -a "${OUTPUT_FILE}" || echo "No hugepages configured" | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

echo "=== 3. Pod Analysis ===" | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

# All pods across namespaces
echo "All Pods (all namespaces):" | tee -a "${OUTPUT_FILE}"
kubectl get pods --all-namespaces -o wide 2>/dev/null | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

# Pod count by namespace
echo "Pod Count by Namespace:" | tee -a "${OUTPUT_FILE}"
kubectl get pods --all-namespaces --no-headers 2>/dev/null | awk '{print $1}' | sort | uniq -c | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

# Pod status summary
echo "Pod Status Summary:" | tee -a "${OUTPUT_FILE}"
kubectl get pods --all-namespaces --no-headers 2>/dev/null | awk '{print $4}' | sort | uniq -c | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

# Pods not running
echo "Pods Not in Running State:" | tee -a "${OUTPUT_FILE}"
kubectl get pods --all-namespaces --field-selector=status.phase!=Running 2>/dev/null | tee -a "${OUTPUT_FILE}" || echo "All pods are running" | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

# Pod resource usage
echo "Pod Resource Usage (Top 10):" | tee -a "${OUTPUT_FILE}"
kubectl top pods --all-namespaces --sort-by=memory 2>/dev/null | head -11 | tee -a "${OUTPUT_FILE}" || echo "Metrics server not available for pod metrics" | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

echo "=== 4. Namespace Analysis ===" | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

echo "All Namespaces:" | tee -a "${OUTPUT_FILE}"
kubectl get namespaces 2>/dev/null | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

echo "=== 5. Service Analysis ===" | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

echo "Services (all namespaces):" | tee -a "${OUTPUT_FILE}"
kubectl get services --all-namespaces 2>/dev/null | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

echo "=== 6. Network Analysis ===" | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

# CNI plugin info (flannel)
echo "CNI Plugin (Flannel) Status:" | tee -a "${OUTPUT_FILE}"
kubectl get pods -n kube-flannel 2>/dev/null | tee -a "${OUTPUT_FILE}" || echo "Flannel namespace not found" | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

echo "Network Policies:" | tee -a "${OUTPUT_FILE}"
kubectl get networkpolicies --all-namespaces 2>/dev/null | tee -a "${OUTPUT_FILE}" || echo "No network policies defined" | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

echo "=== 7. Storage Analysis ===" | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

echo "Persistent Volumes:" | tee -a "${OUTPUT_FILE}"
kubectl get pv 2>/dev/null | tee -a "${OUTPUT_FILE}" || echo "No persistent volumes" | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

echo "Persistent Volume Claims:" | tee -a "${OUTPUT_FILE}"
kubectl get pvc --all-namespaces 2>/dev/null | tee -a "${OUTPUT_FILE}" || echo "No persistent volume claims" | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

echo "Storage Classes:" | tee -a "${OUTPUT_FILE}"
kubectl get storageclass 2>/dev/null | tee -a "${OUTPUT_FILE}" || echo "No storage classes defined" | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

echo "=== 8. Events Analysis ===" | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

echo "Recent Events (last 20):" | tee -a "${OUTPUT_FILE}"
kubectl get events --all-namespaces --sort-by='.lastTimestamp' 2>/dev/null | tail -20 | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

echo "Warning Events:" | tee -a "${OUTPUT_FILE}"
kubectl get events --all-namespaces --field-selector type=Warning 2>/dev/null | tee -a "${OUTPUT_FILE}" || echo "No warning events" | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

echo "=== 9. Component Health ===" | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

echo "Component Status:" | tee -a "${OUTPUT_FILE}"
kubectl get componentstatuses 2>/dev/null | tee -a "${OUTPUT_FILE}" || kubectl get --raw='/readyz?verbose' 2>/dev/null | tee -a "${OUTPUT_FILE}" || echo "Component status API not available" | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

echo "API Server Health:" | tee -a "${OUTPUT_FILE}"
kubectl get --raw='/healthz' 2>/dev/null | tee -a "${OUTPUT_FILE}" || echo "Health check not available" | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

echo "=== 10. Configuration Analysis ===" | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

echo "ConfigMaps (system namespaces):" | tee -a "${OUTPUT_FILE}"
kubectl get configmaps -n kube-system 2>/dev/null | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

echo "Secrets (count by namespace):" | tee -a "${OUTPUT_FILE}"
kubectl get secrets --all-namespaces --no-headers 2>/dev/null | awk '{print $1}' | sort | uniq -c | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

echo "=== Analysis Summary ===" | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

# Generate summary
NODES_OUTPUT=$(kubectl get nodes --no-headers 2>/dev/null)
PODS_OUTPUT=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null)
NAMESPACES_OUTPUT=$(kubectl get namespaces --no-headers 2>/dev/null)

TOTAL_NODES=$(echo "${NODES_OUTPUT}" | wc -l)
READY_NODES=$(echo "${NODES_OUTPUT}" | awk '$2 == "Ready" {count++} END {print count+0}')
TOTAL_PODS=$(echo "${PODS_OUTPUT}" | wc -l)
RUNNING_PODS=$(echo "${PODS_OUTPUT}" | awk '$4 == "Running" {count++} END {print count+0}')
TOTAL_NAMESPACES=$(echo "${NAMESPACES_OUTPUT}" | wc -l)

echo "Summary Statistics:" | tee -a "${OUTPUT_FILE}"
echo "  Total Nodes: ${TOTAL_NODES}" | tee -a "${OUTPUT_FILE}"
echo "  Ready Nodes: ${READY_NODES}" | tee -a "${OUTPUT_FILE}"
echo "  Total Pods: ${TOTAL_PODS}" | tee -a "${OUTPUT_FILE}"
echo "  Running Pods: ${RUNNING_PODS}" | tee -a "${OUTPUT_FILE}"
echo "  Total Namespaces: ${TOTAL_NAMESPACES}" | tee -a "${OUTPUT_FILE}"
echo "" | tee -a "${OUTPUT_FILE}"

# Health assessment
NODES_HEALTHY=false
PODS_HEALTHY=false

if [ "${READY_NODES}" -eq "${TOTAL_NODES}" ] && [ "${TOTAL_NODES}" -gt 0 ]; then
  NODES_HEALTHY=true
fi

if [ "${RUNNING_PODS}" -eq "${TOTAL_PODS}" ] && [ "${TOTAL_PODS}" -gt 0 ]; then
  PODS_HEALTHY=true
fi

if [ "${NODES_HEALTHY}" = true ] && [ "${PODS_HEALTHY}" = true ]; then
  echo "Cluster Health: HEALTHY ✓" | tee -a "${OUTPUT_FILE}"
  echo "All nodes are ready and all pods are running." | tee -a "${OUTPUT_FILE}"
else
  echo "Cluster Health: WARNING ⚠" | tee -a "${OUTPUT_FILE}"
  if [ "${NODES_HEALTHY}" = false ] && [ "${TOTAL_NODES}" -gt 0 ]; then
    echo "Not all nodes are ready. Please investigate node issues." | tee -a "${OUTPUT_FILE}"
  fi
  if [ "${PODS_HEALTHY}" = false ] && [ "${TOTAL_PODS}" -gt 0 ]; then
    echo "Not all pods are running. Please investigate pod issues." | tee -a "${OUTPUT_FILE}"
  fi
  if [ "${TOTAL_NODES}" -eq 0 ] || [ "${TOTAL_PODS}" -eq 0 ]; then
    echo "No nodes or pods found in the cluster." | tee -a "${OUTPUT_FILE}"
  fi
fi

echo "" | tee -a "${OUTPUT_FILE}"
echo "=== Analysis Complete ===" | tee -a "${OUTPUT_FILE}"
echo "Report saved to: ${OUTPUT_FILE}" | tee -a "${OUTPUT_FILE}"
