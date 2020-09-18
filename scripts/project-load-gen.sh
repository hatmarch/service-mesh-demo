#!/bin/bash

set -e -u -o pipefail
declare -r SCRIPT_DIR=$(cd -P $(dirname $0) && pwd)
declare -r DEMO_HOME="$SCRIPT_DIR/.."
declare PROJECT_NAME="demo-app"
declare ROUTE=""
declare ISTIO_ROUTE=""
declare HEADER_ARGS=""
declare QUERY_STRING=""

while (( "$#" )); do
    case "$1" in
        -p|--project)
            PROJECT_NAME=$2
            shift 2
            ;;
        --istio)
            ISTIO_ROUTE="true"
            shift
            ;;
        -h|--header)
            HEADER_ARGS=$2
            shift 2
            ;;
        -q|--querystring)
            QUERY_STRING=$2
            shift 2
            ;;
        -*|--*)
            echo "Error: Unsupported flag $1"
            exit 1
            ;;
        *) 
            ROUTE=$1
            shift
            ;;
    esac
done

declare -r ISTIO_PRJ="${PROJECT_NAME}-istio-system"

if [ -z "$ROUTE" ]; then
    echo "Must specify the *short name* of a route (and optionally whether to use istio gateway.)"
    exit 1
fi

call_curl() {
    local url=$1
    local header_frag=""
    local querystr_frag=""

    if [[ -n "${HEADER_ARGS}" ]]; then
        header_frag=" --header \"$(echo ${HEADER_ARGS})\""
    fi

    if [[ -n "${QUERY_STRING}" ]]; then
        querystr_frag="?${QUERY_STRING}"
    fi

    #    #?user_key=e725ea28683dbf46b1a3d038f59c3bf6"

 #   set -x
    eval "curl $header_frag ${url}${querystr_frag}"
 #   set +x
}


if [ "$ISTIO_ROUTE" ]; then
    URL="$(oc -n ${ISTIO_PRJ} get route istio-ingressgateway -o jsonpath='{.spec.host}')/$ROUTE"
else
    URL="$(oc -n ${PROJECT_NAME} get route $ROUTE -o jsonpath='{.spec.host}')"
fi

read -n 1 -p "Continuous load gen for $URL?  Press Y to proceed and N for single call (y/N)" COMPLETE
if [ "$COMPLETE" != "y" ]; then 
    printf "\nCalling endpoint once\n"
    call_curl http://${URL}
    exit 0
fi

# otherwise, continue the loadgen
while true; do
    call_curl http://${URL}
    sleep .1
done