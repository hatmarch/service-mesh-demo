#!/bin/bash
# NOTE: This script requires that one is logged into OCP with sufficient privileges

SCRIPT_DIR=$(dirname $0)
DEMO_HOME=$SCRIPT_DIR/..

NAMESPACE=$1

if [ -z $1 ]; then
    echo "Didn't specify a namespace, setting to 'demo-app'"
    NAMESPACE="demo-app"
fi

# first get rid of the old project
oc delete project $NAMESPACE

# unenroll from service mesh
oc delete ServiceMeshMemberRoll --all -n istio-system

# pre-reqs
oc adm policy add-scc-to-group anyuid system:authenticated

oc new-project $NAMESPACE

oc adm policy add-scc-to-user privileged -z default -n $NAMESPACE

# Setup a deployer account for azure pipelines
$SCRIPT_DIR/ato-create-deployer-service-account.sh

#
# Customer 
#
# version 1
oc apply -f $DEMO_HOME/customer/kubernetes/Deployment.yml -n $NAMESPACE

# version 2
oc apply -f $DEMO_HOME/customer/kubernetes/Deployment-v2-dotnet-customer.yml -n $NAMESPACE

oc apply -f $DEMO_HOME/customer/kubernetes/Service.yml -n $NAMESPACE

# create a route (eventually replaced with an instio gateway)
oc expose svc customer -n $NAMESPACE

#
# Preference Service
#
oc apply -f $DEMO_HOME/preference/kubernetes/Deployment.yml -n $NAMESPACE
oc apply -f $DEMO_HOME/preference/kubernetes/Service.yml -n $NAMESPACE

# open a route for demonstration purposes
oc expose svc preference -n $NAMESPACE

#
# Recommendation Service
#
# version 1
oc apply -f $DEMO_HOME/recommendation/kubernetes/Deployment.yml  -n $NAMESPACE

# version 2
Oc apply -f $DEMO_HOME/recommendation/kubernetes/Deployment-v2-buggy-only.yml -n $NAMESPACE


oc apply -f $DEMO_HOME/recommendation/kubernetes/Service.yml  -n $NAMESPACE

# open a route for demonstration purposes
oc expose svc recommendation -n $NAMESPACE

