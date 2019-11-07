#!/bin/bash
# NOTE: This script requires that one is logged into OCP with sufficient privileges

PROJECT='tutorial'

# stop service mesh on project
# delete Service Mesh Roll
ORIG_DIR=`pwd`
RELATIVE_SCRIPT_DIR=`dirname "$0"`

# gets rid of virtual services
"$RELATIVE_SCRIPT_DIR/ato-stop-service-mesh.sh" $PROJECT

# delete any of the pods
oc delete project $PROJECT