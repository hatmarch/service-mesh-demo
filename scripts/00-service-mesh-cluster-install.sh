#!/bin/bash
# NOTE: Need to source this file to get the export to work (see: https://stackoverflow.com/questions/10781824/export-not-working-in-my-shell-script)

set -e -u -o pipefail
declare -r SCRIPT_DIR=$(cd -P $(dirname $0) && pwd)
declare -r DEMO_HOME="$SCRIPT_DIR/.."
declare PROJECT_NAME="demo-app"

wait_for_crd()
{
    local CRD=$1
    local PROJECT=$(oc project -q)
    if [[ "${2:-}" ]]; then
        # set to the project passed in
        PROJECT=$2
    fi

    # Wait for the CRD to appear
    while [ -z "$(oc get $CRD 2>/dev/null)" ]; do
        sleep 1
    done 
    sleep 2
    oc wait --for=condition=Established $CRD --timeout=6m -n $PROJECT
}

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

echo "Installing Tekton operator for aspects of setup"
cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-pipelines-operator-rh
  namespace: openshift-operators
spec:
  channel: ocp-4.6
  name: openshift-pipelines-operator-rh
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

declare giteaop_prj=gpte-operators
echo "Installing gitea operator in ${giteaop_prj}"
oc apply -f $DEMO_HOME/kube/gitea/gitea-crd.yaml
oc apply -f $DEMO_HOME/kube/gitea/gitea-cluster-role.yaml
oc get ns $giteaop_prj 2>/dev/null  || { 
    oc new-project $giteaop_prj --display-name="GPTE Operators"
}

# create the service account and give necessary permissions
oc get sa gitea-operator -n $giteaop_prj 2>/dev/null || {
  oc create sa gitea-operator -n $giteaop_prj
}
oc adm policy add-cluster-role-to-user gitea-operator system:serviceaccount:$giteaop_prj:gitea-operator

# install the operator to the gitea project
oc apply -f $DEMO_HOME/kube/gitea/gitea-operator.yaml -n $giteaop_prj
sleep 2
oc rollout status deploy/gitea-operator -n $giteaop_prj


declare -r ISTIO_PRJ="${PROJECT_NAME}-istio-system"
echo "Creating new istio control plane project at $ISTIO_PRJ"
oc get ns $ISTIO_PRJ 2>/dev/null  || { 
    # FIXME: When created as a project an incompatible limit range is applied to it
    oc new-project $ISTIO_PRJ --display-name="Service Mesh Control Plane for $PROJECT_NAME"

    echo "Scanning for incompatible LimitRange"
    sleep 2
    if [[ -n "$(oc get limitrange -n $ISTIO_PRJ 2>/dev/null)" ]]; then
        echo "Removing Limit Ranges"
        oc delete limitrange --all -n $ISTIO_PRJ
    fi
}

# subscribe to service mesh operator (in all projects, does not support per project installation)
oc apply -f "$DEMO_HOME/istiofiles/install/subscription.yaml"

# would love to replace this is an oc wait command, but the csv does not appear to have a status.condition that lends itself to this
# FIXME: Should also check elastic-search but this is in a different project than the other operators
declare -r SUBS=(  jaeger kiali servicemesh )
for SUB in "${SUBS[@]}"; do
    declare CSV=""

    while [[ -z "$CSV" ]]; do
        sleep 2
        CSV=$(oc get sub/$SUB -o jsonpath='{.status.currentCSV}' -n openshift-operators)
    done

    echo "Waiting for operator ${CSV} installation to complete..."
    while true; do
        if [[ "$(oc get csv/$CSV -n ${ISTIO_PRJ} -o jsonpath='{.status.phase}' 2>/dev/null)" == "Succeeded" ]]; then
            break;
        fi

        sleep 5
    done
done

echo "All operators installed in project ${ISTIO_PRJ}"