#!/bin/bash

set -euo pipefail

declare SHELL_TAG=${1:-latest}
declare REGISTRY=${2:-"quay.io"}
declare ACCOUNT=${3:-"mhildenb"}

DOCKER_BUILDKIT=1 docker build --progress=plain -t ${REGISTRY}/${ACCOUNT}/sm-demo-shell:$SHELL_TAG .

docker tag ${REGISTRY}/${ACCOUNT}/sm-demo-shell:${SHELL_TAG} ${REGISTRY}/${ACCOUNT}/sm-demo-shell:latest

docker push ${REGISTRY}/${ACCOUNT}/sm-demo-shell:${SHELL_TAG}
docker push ${REGISTRY}/${ACCOUNT}/sm-demo-shell:latest
