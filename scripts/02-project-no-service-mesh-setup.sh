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

oc get ns ${CICD_PRJ} 2>/dev/null || {
    oc new-project ${CICD_PRJ}
}

oc new-project $PROJECT_NAME --display-name='Service Mesh Demo Project'

echo "Installing tekton components"
declare TKN_FOLDERS=( "volumes" "tasks" "triggers" "pipelines" )
for FOLDER in "${TKN_FOLDERS[@]}"; do
    oc apply -n $CICD_PRJ -R -f "${DEMO_HOME}/kube/tekton/${FOLDER}"
done

# make sure the CICD pipeline account can edit the main project 
# FIXME: Currently set to edit for deployment, but might only really need registry-edit 
# if it's just updating the internal registry
oc adm policy add-role-to-user edit -n $PROJECT_NAME system:serviceaccount:${CICD_PRJ}:pipeline

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

echo "Initializing gitea"
oc create -f $DEMO_HOME/kube/gitea/gitea-init-taskrun.yaml -n $CICD_PRJ
tkn tr logs -L -f -n ${CICD_PRJ}

#
# Customer 
#
# version 1
oc apply -f $DEMO_HOME/kube/customer/Deployment.yml -n $PROJECT_NAME

# version 2
oc apply -f $DEMO_HOME/kube/customer/Deployment-v2.yml -n $PROJECT_NAME

# uncomment for a dotnet version of customer v2
# oc apply -f $DEMO_HOME/kube/customer/Deployment-v2-dotnet-customer.yml -n $PROJECT_NAME

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

# version 3 
# This is setup so that we can update the image stream and trigger an update on the version
# Notice that the options are based on a jib build, as per https://github.com/GoogleContainerTools/jib/blob/master/docs/faq.md#how-do-i-set-parameters-for-my-image-at-runtime
oc create is recommendation-v3 -n $PROJECT_NAME
oc import-image recommendation-v3 --from=quay.io/mhildenb/sm-demo-recommendation:v3 --reference-policy=local --confirm=true -n $PROJECT_NAME
oc new-app recommendation-v3 -l app=recommendation,version=v3,app.kubernetes.io/part-of=Recommendation \
    -e JAVA_TOOL_OPTIONS="-Xdebug -Xrunjdwp:transport=dt_socket,address=5000,server=y,suspend=n" -n $PROJECT_NAME
sleep 1
# ensure sidecar injection
oc patch deploy/recommendation-v3 --patch '{"spec":{"template":{"metadata":{"annotations": { "sidecar.istio.io/inject":"true" }}}}}'
oc expose svc recommendation-v3 -n $PROJECT_NAME

oc apply -f $DEMO_HOME/kube/recommendation/Service.yml  -n $PROJECT_NAME

# open a route for demonstration purposes
oc expose svc recommendation -n $PROJECT_NAME

