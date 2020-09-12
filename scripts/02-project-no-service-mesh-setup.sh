#!/bin/bash
# NOTE: This script requires that one is logged into OCP with sufficient privileges
set -e -u -o pipefail
declare -r SCRIPT_DIR=$(cd -P $(dirname $0) && pwd)
declare -r DEMO_HOME="$SCRIPT_DIR/.."
declare PROJECT_NAME="demo-app"
declare CICD_PRJ="${PROJECT_NAME}-cicd"

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

# first get rid of the old project if it exists
oc get ns ${PROJECT_NAME} 2>/dev/null && oc delete project $PROJECT_NAME

while [[ "$(oc get ns ${PROJECT_NAME} 2>/dev/null)" ]]; do
    echo "Waiting for project deletion."
    sleep 1
done

# pre-reqs
# oc adm policy add-scc-to-group anyuid system:authenticated

oc new-project $PROJECT_NAME --display-name='Service Mesh Demo Project'
oc get ns ${CICD_PRJ} 2>/dev/null || {
    oc new-project ${CICD_PRJ}
}
#
# Customer 
#
# version 1
oc apply -f $DEMO_HOME/kube/customer/Deployment.yml -n $PROJECT_NAME

# version 2
oc apply -f $DEMO_HOME/kube/customer/Deployment-v2-dotnet-customer.yml -n $PROJECT_NAME

oc apply -f $DEMO_HOME/kube/customer/Service.yml -n $PROJECT_NAME

# create a route (eventually replaced with an instio gateway)
oc expose svc customer -n $PROJECT_NAME

#
# Preference Service
#
oc apply -f $DEMO_HOME/kube/preference/Deployment.yml -n $PROJECT_NAME
oc apply -f $DEMO_HOME/kube/preference/Service.yml -n $PROJECT_NAME

# open a route for demonstration purposes
oc expose svc preference -n $PROJECT_NAME

#
# Recommendation Service
#
# version 1
oc apply -f $DEMO_HOME/kube/recommendation/Deployment.yml  -n $PROJECT_NAME

# version 2
oc apply -f $DEMO_HOME/kube/recommendation/Deployment-v2-buggy-only.yml -n $PROJECT_NAME

# version 3 (NOTE: Don't deploy version 3 by default, we expect to build it)
# oc apply -f $DEMO_HOME/kube/recommendation/Deployment-v3.yml -n $NAMESPACE

oc apply -f $DEMO_HOME/kube/recommendation/Service.yml  -n $PROJECT_NAME

# open a route for demonstration purposes
oc expose svc recommendation -n $PROJECT_NAME

echo "Initiatlizing git repository in gitea and configuring webhooks"
oc apply -f $DEMO_HOME/kube/gitea/gitea-server-cr.yaml -n $CICD_PRJ
oc wait --for=condition=Running Gitea/gitea-server -n $CICD_PRJ --timeout=2m
echo -n "Waiting for gitea deployment to appear..."
while [[ -z "$(oc get deploy gitea -n $CICD_PRJ 2>/dev/null)" ]]; do
    echo -n "."
    sleep 1
done
echo "done!"
oc rollout status deploy/gitea -n $CICD_PRJ

# fixme: Run the gitea pipeline task