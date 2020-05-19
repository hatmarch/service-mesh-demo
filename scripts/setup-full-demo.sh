#!/bin/bash

# Fully setups the demo on the cluster

set -e -u -o pipefail
declare -r SCRIPT_DIR=$(cd -P $(dirname $0) && pwd)
declare -r DEMO_HOME="$SCRIPT_DIR/.."
declare PROJECT_NAME="demo-app"

while (( "$#" )); do
    case "$1" in
        -p|--project)
            PROJECT_NAME=$2
            shift 2
            ;;
        -*|--*)
            echo "Error: Unsupported flag $1"
            exit 1
            ;;
        *) 
            break
    esac
done

$SCRIPT_DIR/00-service-mesh-cluster-install.sh -p $PROJECT_NAME
$SCRIPT_DIR/01-provision-service-mesh.sh -p $PROJECT_NAME
$SCRIPT_DIR/02-project-no-service-mesh-setup.sh -p $PROJECT_NAME
$SCRIPT_DIR/03-project-apply-service-mesh.sh -p $PROJECT_NAME

echo "Done!"