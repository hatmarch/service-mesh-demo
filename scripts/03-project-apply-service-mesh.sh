#!/bin/bash

SCRIPT_DIR=$(dirname $0)
DEMO_HOME=$SCRIPT_DIR/..

NAMESPACE=$1

if [ -z $1 ]; then
    echo "Didn't specify a namespace, setting to 'demo-app'"
    NAMESPACE="demo-app"
fi

# Delete any old installations
oc delete Gateway customer
oc delete VirtualService customer
oc delete VirtualService recommendation
oc delete DestinationRule customer
oc delete DestinationRule recommendation

# Customer gateway, virtual service, and destination rule
oc apply -f $DEMO_HOME/customer/kubernetes/Gateway-no-virtual-service.yml -n $NAMESPACE
oc apply -f $DEMO_HOME/customer/kubernetes/destination-rule-customer-v1-v2.yml -n $NAMESPACE
oc apply -f $DEMO_HOME/customer/kubernetes/virtual-service-customer-v1_and_v2.yml -n $NAMESPACE

# Add the preference virtual service and destination rule (mostly for making sure no retry on error)
oc apply -f $DEMO_HOME/preference/kubernetes/destination-rule-preference.yml -n $NAMESPACE
oc apply -f $DEMO_HOME/preference/kubernetes/virtual-service-preference.yml -n $NAMESPACE

# Add the destination rule and virtual service for Recommendation
oc apply -f $DEMO_HOME/istiofiles/destination-rule-recommendation-v1-v2.yml -n $NAMESPACE
oc apply -f $DEMO_HOME/istiofiles/virtual-service-recommendation-v1_and_v2_initial.yml -n $NAMESPACE

# enroll in the service mesh
oc apply -f $SCRIPT_DIR/service-mesh-roll.yaml -n istio-system

# allow other routes not through istio gateway to function by default
oc delete NetworkPolicy istio-mesh -n $NAMESPACE

# give the enrollment in the service mesh a chance to propagate
sleep 5

# stop the pods and make them start up again to get sidecars
$SCRIPT_DIR/project-bounce-pods.sh $NAMESPACE
