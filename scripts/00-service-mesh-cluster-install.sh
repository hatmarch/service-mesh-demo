#!/bin/bash
# NOTE: Need to source this file to get the export to work (see: https://stackoverflow.com/questions/10781824/export-not-working-in-my-shell-script)

SCRIPT_DIR=$(dirname $0)
DEMO_HOME=$SCRIPT_DIR/..

# Delete any previous istio-system
oc delete project istio-system

# Create the istio-system project
oc adm new-project istio-system --display-name="Service Mesh System"

# install the official Redhat operator catalog
oc apply -f "$DEMO_HOME/istiofiles/install/redhat-operators-csc.yaml"

# subscribe to service mesh operator and all dependent operators
oc apply -f "$DEMO_HOME/istiofiles/install/subscription.yaml"