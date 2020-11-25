#!/bin/bash

# Removes the demo from the cluster.  By default this will remove the Istio operators
set -u -o pipefail
declare -r SCRIPT_DIR=$(cd -P $(dirname $0) && pwd)
declare -r DEMO_HOME="$SCRIPT_DIR/.."
declare PROJECT_NAME="demo-app"
declare REMOVE_OPERATORS="true"
declare FORCE=""

while (( "$#" )); do
    case "$1" in
        -p|--project)
            PROJECT_NAME=$2
            shift 2
            ;;
        -f|--force) 
            FORCE="true"
            shift 1
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

remove-operator()
{
    OPERATOR_NAME=$1
    OPERATOR_PRJ=${2:-openshift-operators}

    echo "Uninstalling operator: ${OPERATOR_NAME} from project ${OPERATOR_PRJ}"
    # NOTE: there is intentionally a space before "currentCSV" in the grep since without it f.currentCSV will also be matched which is not what we want
    CURRENT_CSV=$(oc get sub ${OPERATOR_NAME} -n ${OPERATOR_PRJ} -o yaml | grep " currentCSV:" | sed "s/.*currentCSV: //")
    oc delete sub ${OPERATOR_NAME} -n ${OPERATOR_PRJ} || true
    oc delete csv ${CURRENT_CSV} -n ${OPERATOR_PRJ} || true

    # Attempt to remove any orphaned install plan named for the csv
    oc get installplan -n ${OPERATOR_PRJ} | grep ${CURRENT_CSV} | awk '{print $1}' 2>/dev/null | xargs oc delete installplan -n $OPERATOR_PRJ
}

remove-crds() 
{
    API_NAME=$1

    oc get crd -oname | grep "${API_NAME}" | xargs oc delete
}

# Assumes proxy has been setup
force-clean() {
    declare NAMESPACE=$1

    echo "Force removing project $NAMESPACE"

    oc get namespace $NAMESPACE -o json | jq '.spec = {"finalizers":[]}' > /tmp/temp.json
    curl -k -H "Content-Type: application/json" -X PUT --data-binary @/tmp/temp.json 127.0.0.1:8001/api/v1/namespaces/$NAMESPACE/finalize
    rm /tmp/temp.json
}

declare ISTIO_PRJ="${PROJECT_NAME}-istio-system"
declare CICD_PRJ="${PROJECT_NAME}-cicd"

# NOTE: before deleting any project involving istio, the ServiceMeshControlPlane must first be deleted, as per here: https://access.redhat.com/solutions/4597081
oc delete smcp --all -n $ISTIO_PRJ

# The cleanup can get stuck on the deletion of the kiali dashboard
oc delete kiali --all -n $ISTIO_PRJ

# Delete all the projects
declare PROJECTS=( ${PROJECT_NAME} ${ISTIO_PRJ} ${CICD_PRJ} )
for PROJECT in "${PROJECTS[@]}"; do
    oc get ns ${PROJECT} 2>/dev/null && oc delete project ${PROJECT}
done

if [[ "${REMOVE_OPERATORS}" ]]; then

    echo "Removing Gitea Operator"
    oc delete project gpte-operators || true
    oc delete clusterrole gitea-operator || true
    remove-crds gitea || true

    declare OPERATORS=( servicemesh jaeger kiali openshift-pipelines-operator )
    for OPERATOR in "${OPERATORS[@]}"; do
        remove-operator ${OPERATOR} || true
    done

    remove-operator elastic-search openshift-operators-redhat || true

    # Clean up specific webhooks 
    # per https://docs.openshift.com/container-platform/4.6/service_mesh/v2x/installing-ossm.html#ossm-remove-cleanup_installing-ossm
    OPERATOR_PROJECT="openshift-operators"
    oc delete validatingwebhookconfiguration/${OPERATOR_PROJECT}.servicemesh-resources.maistra.io
    oc delete mutatingwebhookconfigurations/${OPERATOR_PROJECT}.servicemesh-resources.maistra.io
    oc delete -n ${OPERATOR_PROJECT} daemonset/istio-node

    oc delete clusterrole/istio-admin clusterrole/istio-cni clusterrolebinding/istio-cni

    # declare CRDS=(maistra jaeger kiali elasticsearch)
    declare CRDS=( '.*\.istio\.io' '.*\.maistra\.io' '.*\.kiali\.io' )
    for CRD in "${CRDS[@]}"; do
        remove-crds ${CRD} || true
    done

fi

declare PROXY_PID=""
if [[ ! -z "$FORCE" ]]; then
    echo -n "opening proxy"

    oc proxy &
    PROXY_PID=$!
fi

# wait until all projects are fully deleted
for PROJECT in "${PROJECTS[@]}"; do
    while [[ "$(oc get ns ${PROJECT} 2>/dev/null)" ]]; do

        if [[ ! -z "$FORCE" ]]; then
            force-clean "${PROJECT}"
        fi

        echo "Waiting for ${PROJECT} deletion."
        sleep 1
    done
done

# FIXME: Wait until all the operators are removed


if [[ ! -z "$PROXY_PID" ]]; then
    echo "closing proxy"
    kill $PROXY_PID
fi

