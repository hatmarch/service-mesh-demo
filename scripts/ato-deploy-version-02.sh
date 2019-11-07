#!/bin/bash

# NOTE: This is probably best done whilst showing Kaili's versioned App Graph and with
# ato-load-gen.sh running in background

wait_for_user()
{
    local message=$1

    while true; do
        read -n 1 -p "$message" COMPLETE
        if [ "$COMPLETE" == "y" ]; then 
            printf "\n"
            break
        fi
    done
}

oc apply -f recommendation/kubernetes/Deployment-v2.yml -n tutorial

wait_for_user "Press 'y' you're ready to setup istio rules to route only to v1: "

# All route to v1
oc -n tutorial apply -f istiofiles/destination-rule-recommendation-v1-v2.yml
oc -n tutorial apply -f istiofiles/virtual-service-recommendation-v1.yml

wait_for_user "Press 'y' you're ready to set v2 as canary release: "

# 90% of traffic to v1, with v2 as canary
oc -n tutorial apply -f istiofiles/virtual-service-recommendation-v1_and_v2.yml

# 50% v1 and v2
wait_for_user "Press 'y' to send 50% of traffic to v2: "
oc -n tutorial apply -f istiofiles/virtual-service-recommendation-v1_and_v2_50_50.yml

# 100$ to v2
wait_for_user "Press 'y' to send all traffic to v2: "
oc -n tutorial apply -f istiofiles/virtual-service-recommendation-v2.yml

# TODO: return service to original

# TODO: Route based on headers, see also 
# oc -n tutorial create -f istiofiles/virtual-service-safari-recommendation-v2.yml

# See also these curl commands “curl -H 'User-Agent: Safari' \
# curl -A Firefox customer-tutorial.$(minishift ip).nip.io
# curl -H 'User-Agent: Safari' customer-tutorial.$(minishift ip).nip.io

# TODO: Add a V3 that breaks and show that rolling back?

