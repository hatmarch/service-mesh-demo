#!/bin/bash

echo "Demo home is: $DEMO_HOME"

cd $DEMO_HOME
# remove destination rule and deployment and virtual service
oc delete -f recommendation/kubernetes/Deployment-v2-buggy.yml
