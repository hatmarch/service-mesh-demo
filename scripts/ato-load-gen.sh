#!/bin/bash

ROUTE=$1
if [ -z "$ROUTE" ]; then
    echo "Must specify the short name of a route (and optionally whether to use istio gateway.)"
    exit 1
fi


if [ "$2" == 'istio' ]; then
    URL="$(oc -n istio-system get route istio-ingressgateway -o jsonpath='{.spec.host}')/$ROUTE"
else
    URL="$(oc -n tutorial get route $ROUTE -o jsonpath='{.spec.host}')"
fi

read -n 1 -p "Starting load gen for $URL.  Proceed? (y/N)" COMPLETE
if [ "$COMPLETE" != "y" ]; then 
    printf "\nLoadgen cancelled...\n"
    exit 1
fi

while true; do
    curl $URL
    sleep .1
done