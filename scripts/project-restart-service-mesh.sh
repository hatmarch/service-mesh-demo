#!/bin/bash

SCRIPT_DIR=$(dirname $0)
DEMO_HOME=$SCRIPT_DIR/..

PROJECT=$1

if [ -z $1 ]; then
    echo "Didn't specify a PROJECT, setting to 'demo-app'"
    PROJECT="demo-app"
fi

# TODO: Patch the servicemeshroll instead
oc apply -f ${SCRIPT_DIR}/service-mesh-roll.yaml -n istio-system

# allow other routes not through istio gateway to function by default
oc delete NetworkPolicy istio-mesh -n $PROJECT

sleep 1

# by default we bounce the pods after running script,
# but a second parameter will prevent this
NO_BOUNCE=$2
if [ -z "$NO_BOUNCE" ]; then
    "$SCRIPT_DIR/ato-bounce-pods.sh" $PROJECT
fi