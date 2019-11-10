#!/bin/bash

PROJECT=$1
if [ -z "$PROJECT" ]; then
    echo "Must specify a project whose pods you want bounced."
    exit 1
fi

for POD in `oc get pods -n $PROJECT --no-headers | awk {'print $1'}`
do
    oc delete pod $POD -n $PROJECT &
done

echo "\n"
