#!/bin/bash
set -e 

# USAGE:
# ./monitor_snapshot.sh SNAPSHOT_NAME INTEGRATION_TEST_NAME OUTPUT_FILE_NAME

snapshot=$1
integration_test=$2
output_file=$3

# epoch=$(date +%s)
# 
# snapshot="snapshot-sample-$epoch"
# integration_test=konflux-sandbox-enterprise-contract
# output_file=./ec-logs.txt
# 
# kubectl get snapshot konflux-sandbox-x8wck -o json | jq --arg name "$snapshot" '{apiVersion, kind, spec, metadata: {name: $name, namespace: .metadata.namespace, labels: {"test.appstudio.openshift.io/type": "override"} }}' | kubectl apply -f -

kubectl wait --for create snapshot "$snapshot"
kubectl label snapshot "$snapshot" "test.appstudio.openshift.io/run=$integration_test"

pipelinerun=$(kubectl get pr -l "appstudio.openshift.io/snapshot=$snapshot,test.appstudio.openshift.io/scenario=$integration_test" --no-headers | awk '{print $1}')

pod_name="${pipelinerun}-verify-pod"

echo "waiting for $pod_name to be created"
kubectl wait --for=create pod "$pod_name"
echo "waiting for $pod_name to finish"
kubectl wait --for='jsonpath={.status.conditions[?(@.reason=="PodCompleted")].status}=True' pod "$pod_name"


kubectl logs "$pod_name" step-report-json > $output_file



