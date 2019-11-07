#!/bin/bash
# NOTE: This script requires that one is logged into OCP with sufficient privileges

TUTORIAL_PROJECT_BASE="$HOME/Documents/Development/"
PROJECT="istio-tutorial"
TUTORIAL_DIR="${TUTORIAL_PROJECT_BASE}${PROJECT}"

if [ -d "$TUTORIAL_DIR" ]; then
    echo "Project downloaded"
else
    echo "project not downloaded!"
    return 1
fi

cd $TUTORIAL_DIR

# unenroll from service mesh
oc delete ServiceMeshMemberRoll --all -n istio-system

# pre-reqs
oc adm policy add-scc-to-group anyuid system:authenticated

oc new-project tutorial

oc adm policy add-scc-to-user privileged -z default -n tutorial

# Setup a deployer account for azure pipelines
$TUTORIAL_DIR/scripts/ato-demo-version-03/ato-create-deployer-service-account.sh

oc apply -f customer/kubernetes/Deployment.yml -n tutorial

oc create -f customer/kubernetes/Service.yml -n tutorial

# create a route (eventually replaced with an instio gateway)
oc expose svc customer

#
# Preference Service
#
oc apply -f preference/kubernetes/Deployment.yml -n tutorial
oc create -f preference/kubernetes/Service.yml -n tutorial

# open a route for demonstration purposes
oc expose svc preference

#
# Recommendation Service
#
oc apply -f recommendation/kubernetes/Deployment.yml  -n tutorial
oc create -f recommendation/kubernetes/Service.yml  -n tutorial

# open a route for demonstration purposes
oc expose svc recommendation

