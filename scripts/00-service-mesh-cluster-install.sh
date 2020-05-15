#!/bin/bash
# NOTE: Need to source this file to get the export to work (see: https://stackoverflow.com/questions/10781824/export-not-working-in-my-shell-script)

set -e -u -o pipefail
declare -r SCRIPT_DIR=$(cd -P $(dirname $0) && pwd)
declare -r DEMO_HOME="$SCRIPT_DIR/.."
declare PROJECT_NAME="demo-app"

while (( "$#" )); do
    case "$1" in
        -p)
            PROJECT_NAME=$2
            shift 2
            ;;
        -*|--*)
            echo "Error: Unsupported flag $1"
            exit 1
            ;;
        *) 
            break
    esac
done

declare -r ISTIO_PRJ="${PROJECT_NAME}-istio-system"
echo "Creating new istio control plane project at $ISTIO_PRJ"
oc get ns $ISTIO_PRJ 2>/dev/null  || { 
    oc new-project $ISTIO_PRJ --display-name="Service Mesh Control Plane for $PROJECT_NAME"
}

# install the official Redhat operator catalog
oc apply -f "$DEMO_HOME/istiofiles/install/redhat-operators-csc.yaml"

# subscribe to service mesh operator (in all projects, does not support per project installation)
oc apply -f "$DEMO_HOME/istiofiles/install/subscription.yaml"

# would love to replace this is an oc wait command, but the csv does not appear to have a status.condition that lends itself to this
echo "Waiting for operator installation to complete..."
while true; do
    if [[ "$(oc get csv/servicemeshoperator.v1.1.1 -o jsonpath='{.status.phase}' 2>/dev/null)" == "Succeeded" ]]; then
        break;
    fi

    sleep 5
done
echo "done."