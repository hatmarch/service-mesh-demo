#!/bin/bash

PROJECT="demo-app"

ROUTE=$1
if [ -z "$ROUTE" ]; then
    echo "Must specify the *short name* of a route (and optionally whether to use istio gateway.)"
    exit 1
fi


if [ "$2" == 'istio' ]; then
    URL="$(oc -n istio-system get route istio-ingressgateway -o jsonpath='{.spec.host}')/$ROUTE"
else
    URL="$(oc -n $PROJECT get route $ROUTE -o jsonpath='{.spec.host}')"
fi

read -n 1 -p "Continuous load gen for $URL?  Press Y to proceed and N for single call (y/N)" COMPLETE
if [ "$COMPLETE" != "y" ]; then 
    printf "\nCalling endpoint once\n"
    curl $URL
    exit 0
fi

# otherwise, continue the loadgen
while true; do
    curl $URL
    sleep .1
done