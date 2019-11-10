#!/bin/bash
# NOTE: This script requires that one is logged into OCP with sufficient privileges

# should come from the higher order script that calls this
echo "Project is $NAMESPACE"

oc project $NAMESPACE

# NOTE: If this account doesn't exist, you will need to setup token again (see below)
# If the service account is deleted you will need to setup service account tokens (e.g. with Azure pipelines)
# again.  Thus we put it outside the tutorial project (which will get deleted every time we reset the demo)
oc create serviceaccount durable-azure-deploy -n default 

oc policy add-role-to-user edit system:serviceaccount:default:durable-azure-deploy


#
# To get secrets for deployment from service account
#
# oc get sa durable-azure-deploy -o yaml -n default

## Get the token secret and then do

# oc get secret <token_secret> -o yaml
