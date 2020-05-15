#!/bin/bash

# Removes the demo from the cluster.  By default this will remove the Istio operators
set -u -o pipefail
declare -r SCRIPT_DIR=$(cd -P $(dirname $0) && pwd)
declare -r DEMO_HOME="$SCRIPT_DIR/.."
declare PROJECT_NAME="demo-app"
declare REMOVE_OPERATORS="true"

while (( "$#" )); do
    case "$1" in
        -p|--project)
            PROJECT_NAME=$2
            shift 2
            ;;
        -k|--keep-operators)
            REMOVE_OPERATORS=""
            shift 1
            ;;
        -*|--*)
            echo "Error: Unsupported flag $1"
            exit 1
            ;;
        *) 
            break
    esac
done

declare ISTIO_PRJ="${PROJECT_NAME}-istio-system"

# Delete all the projects
declare PROJECTS=( ${PROJECT_NAME} ${ISTIO_PRJ} )
for PROJECT in "${PROJECTS[@]}"; do
    oc get ns ${PROJECT} 2>/dev/null && oc delete project ${PROJECT}
done

if [[ "${REMOVE_OPERATORS}" ]]; then
    declare SUBS=( servicemesh jaeger kiali elastic-search )
    for SUB in "${SUBS[@]}"; do
        declare CSV=$(oc get sub/$SUB -o jsonpath='{.status.currentCSV}' -n openshift-operators)
        oc delete sub/$SUB -n openshift-operators
        oc delete csv/$CSV -n openshift-operators
    done
fi

# wait until all projects are fully deleted
for PROJECT in "${PROJECTS[@]}"; do
    while [[ "$(oc get ns ${PROJECT} 2>/dev/null)" ]]; do
        echo "Waiting for ${PROJECT} deletion."
        sleep 1
    done
done

# FIXME: Wait until all the operators are removed



