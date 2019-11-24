#!/bin/bash
# NOTE: This script requires that one is logged into OCP with sufficient privileges

SCRIPT_DIR=$(dirname $0)
DEMO_HOME=$SCRIPT_DIR/..

NAMESPACE=$1

if [ -z $1 ]; then
    echo "Didn't specify a namespace, setting to 'demo-app'"
    NAMESPACE="demo-app"
fi

# gets rid of virtual services
${SCRIPT_DIR}/ato-stop-service-mesh.sh $NAMESPACE

# delete any of the pods
oc delete project $NAMESPACE