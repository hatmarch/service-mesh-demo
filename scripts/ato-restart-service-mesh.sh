#!/bin/bash

PROJECT=$1
if [ -z "$PROJECT" ]; then
    echo "Must specify a project whose pods you put in service mesh."
    exit 1
fi

ORIG_DIR=`pwd`
RELATIVE_SCRIPT_DIR=`dirname "$0"`
SCRIPT_DIR="$ORIG_DIR/$RELATIVE_SCRIPT_DIR"

# TODO: Patch the servicemeshroll instead
oc apply -f "$RELATIVE_SCRIPT_DIR/service-mesh-roll.yaml" -n istio-system

# allow other routes not through istio gateway to function by default
oc delete NetworkPolicy istio-mesh -n $PROJECT

# by default we bounce the pods after running script,
# but a second parameter will prevent this
NO_BOUNCE=$2
if [ -z "$NO_BOUNCE" ]; then
    "$SCRIPT_DIR/ato-bounce-pods.sh" $PROJECT
fi