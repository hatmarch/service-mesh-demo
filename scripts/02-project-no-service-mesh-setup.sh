#!/bin/bash
# NOTE: This script requires that one is logged into OCP with sufficient privileges
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

# first get rid of the old project if it exists
oc get ns ${PROJECT_NAME} 2>/dev/null && oc delete project $PROJECT_NAME

while [[ "$(oc get ns ${PROJECT_NAME} 2>/dev/null)" ]]; do
    echo "Waiting for project deletion."
    sleep 1
done

# pre-reqs
# oc adm policy add-scc-to-group anyuid system:authenticated

oc new-project $PROJECT_NAME --display-name='Service Mesh Demo Project'

# oc adm policy add-scc-to-user privileged -z default -n $NAMESPACE

# Setup a deployer account for azure pipelines
# $SCRIPT_DIR/ato-create-deployer-service-account.sh

#
# Customer 
#
# version 1
oc apply -f $DEMO_HOME/customer/kubernetes/Deployment.yml -n $PROJECT_NAME

# version 2
oc apply -f $DEMO_HOME/customer/kubernetes/Deployment-v2-dotnet-customer.yml -n $PROJECT_NAME

oc apply -f $DEMO_HOME/customer/kubernetes/Service.yml -n $PROJECT_NAME

# create a route (eventually replaced with an instio gateway)
oc expose svc customer -n $PROJECT_NAME

#
# Preference Service
#
oc apply -f $DEMO_HOME/preference/kubernetes/Deployment.yml -n $PROJECT_NAME
oc apply -f $DEMO_HOME/preference/kubernetes/Service.yml -n $PROJECT_NAME

# open a route for demonstration purposes
oc expose svc preference -n $PROJECT_NAME

#
# Recommendation Service
#
# version 1
oc apply -f $DEMO_HOME/recommendation/kubernetes/Deployment.yml  -n $PROJECT_NAME

# version 2
oc apply -f $DEMO_HOME/recommendation/kubernetes/Deployment-v2-buggy-only.yml -n $PROJECT_NAME

# version 3 (NOTE: Don't deploy version 3 by default, we expect to build it)
# oc apply -f $DEMO_HOME/recommendation/kubernetes/Deployment-v3.yml -n $NAMESPACE

oc apply -f $DEMO_HOME/recommendation/kubernetes/Service.yml  -n $PROJECT_NAME

# open a route for demonstration purposes
oc expose svc recommendation -n $PROJECT_NAME

