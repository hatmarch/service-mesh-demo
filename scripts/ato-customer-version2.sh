#!/bin/bash

oc delete Gateway customer
oc delete VirtualService customer

oc create -f ../customer/kubernetes/Gateway-no-virtual-service.yml
oc create -f ../customer/destination-rule-customer-v1-v2.yml
oc create -f ../customer/virtual-service-customer-v1_only.yml

oc create -f ../customer/virtual-service-customer-v1_and_v2.yml
