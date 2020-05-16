#!/bin/bash

set -e -u -o pipefail
declare -r SCRIPT_DIR=$(cd -P $(dirname $0) && pwd)
declare -r DEMO_HOME="$SCRIPT_DIR/.."
declare PROJECT_NAME="demo-app"
declare ROUTE=""
declare ISTIO_ROUTE=""
declare HEADER_ARGS=""

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
    if [[ "$HEADER_ARGS" ]]; then
        curl -H "${HEADER_ARGS}" $1
    else
        curl $1
    fi
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