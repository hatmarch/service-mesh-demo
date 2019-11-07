#!/bin/bash

PROJECT=$1
if [ -z "$PROJECT" ]; then
    echo "Must specify a project whose pods you want bounced."
    exit 1
fi

oc delete ServiceMeshMemberRoll --all -n istio-system
oc delete virtualservice --all -n $PROJECT
oc delete gateway --all -n $PROJECT

ORIG_DIR=`pwd`
RELATIVE_SCRIPT_DIR=`dirname "$0"`
"$ORIG_DIR/$RELATIVE_SCRIPT_DIR/ato-bounce-pods.sh" $PROJECT