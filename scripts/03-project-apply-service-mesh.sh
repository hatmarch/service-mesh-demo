#!/bin/bash

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

# Delete any old installations
oc delete Gateway --all -n $PROJECT_NAME
oc delete VirtualService --all -n $PROJECT_NAME
oc delete DestinationRule --all -n $PROJECT_NAME

# install the ServiceMeshMemoryRoll resource which will 
# define which projects will participate in the service mesh (and thus will have sidecar injected into them)
sed "s/demo-app/${PROJECT_NAME}/g" ${DEMO_HOME}/istiofiles/install/service-mesh-roll.yaml | oc apply -f - -n $ISTIO_PRJ

# Customer gateway, virtual service, and destination rule
oc apply -f $DEMO_HOME/customer/kubernetes/Gateway-no-virtual-service.yml -n $PROJECT_NAME
oc apply -f $DEMO_HOME/customer/kubernetes/destination-rule-customer-v1-v2.yml -n $PROJECT_NAME
oc apply -f $DEMO_HOME/customer/kubernetes/virtual-service-customer-v1_and_v2.yml -n $PROJECT_NAME

# Add the preference virtual service and destination rule (mostly for making sure no retry on error)
oc apply -f $DEMO_HOME/preference/kubernetes/destination-rule-preference.yml -n $PROJECT_NAME
oc apply -f $DEMO_HOME/preference/kubernetes/virtual-service-preference.yml -n $PROJECT_NAME

# Add the destination rule and virtual service for Recommendation
oc apply -f $DEMO_HOME/istiofiles/destination-rule-recommendation-v1-v2.yml -n $PROJECT_NAME
oc apply -f $DEMO_HOME/istiofiles/virtual-service-recommendation-v1_and_v2_initial.yml -n $PROJECT_NAME

# FIXME: allow other routes not through istio gateway to function by default
# oc delete NetworkPolicy istio-expose-route -n $PROJECT_NAME

echo "Waiting for Service Mesh Member initialization"
while true; do
    COMPONENT_COUNT="$(oc get smmr/default -n ${ISTIO_PRJ} -o jsonpath='{.status.annotations.configuredMemberCount}' 2>/dev/null)"
    if [[ "${COMPONENT_COUNT}" == "1/1" ]]; then
        break;
    fi

    # appears 
    # echo "progress: ${COMPONENT_COUNT}"
    sleep 1
done
echo "done"

# kill all the pods (which will cause them to recreate and when they do so they will get their sidecars
$SCRIPT_DIR/project-bounce-pods.sh $PROJECT_NAME
