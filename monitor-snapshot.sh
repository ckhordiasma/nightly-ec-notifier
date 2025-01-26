#!/bin/bash

# kubectl get snapshot

# TODO parameterize the input snapshot_name and integration_test

epoch=$(date +%s)
snapshot_name="snapshot-sample-$epoch"


kubectl get snapshot konflux-sandbox-x8wck -o json | jq --arg name "$snapshot_name" '{apiVersion, kind, spec, metadata: {name: $name, namespace: .metadata.namespace, labels: {"test.appstudio.openshift.io/type": "override"} }}' | kubectl apply -f -

integration_test=konflux-sandbox-enterprise-contract

kubectl label snapshot "$snapshot_name" "test.appstudio.openshift.io/run=$integration_test"

pipelinerun=$(kubectl get pr -l "appstudio.openshift.io/snapshot=$snapshot_name,test.appstudio.openshift.io/scenario=$integration_test" --no-headers | awk '{print $1}')

pod_name="${pipelinerun}-verify-pod"

echo "waiting for $pod_name to be created"
kubectl wait --for=create pod "$pod_name"
echo "waiting for $pod_name to finish"
kubectl wait --for='jsonpath={.status.conditions[?(@.reason=="PodCompleted")].status}=True' pod "$pod_name"


logs=$(kubectl logs "$pod_name" step-report-json)

echo $logs

# TODO parse logs

# TODO send to slack

