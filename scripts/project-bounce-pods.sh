#!/bin/bash

set -e -u -o pipefail

declare -r PROJECT=$1
if [ -z "$PROJECT" ]; then
    echo "Must specify a project whose pods you want bounced."
    exit 1
fi

declare -r LABELS=( "customer" "preference" "recommendation" )

# delete pods for each label
for LABEL in "${LABELS[@]}"; do
    echo "Deleting pods with label: ${LABEL}"
    oc delete pod -l app=${LABEL} -n $PROJECT
done

# wait for all pods to become available

for LABEL in "${LABELS[@]}"
do
    echo "Waiting for all ${LABEL} deployments to be ready."
    oc wait deployment -n $PROJECT -l app=${LABEL} --for=condition="Available" --timeout=2m
done
