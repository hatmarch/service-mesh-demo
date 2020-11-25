# For Use with RHPDS using these instructions: https://learning.redhat.com/mod/scorm/player.php?a=1220&currentorg=&scoid=2877&sesskey=AH5CWj7OL9&display=popup&mode=normal

set -e -u -o pipefail
declare -r SCRIPT_DIR=$(cd -P $(dirname $0) && pwd)
declare -r DEMO_HOME="$SCRIPT_DIR/.."
declare PROJECT_NAME="demo-app"

while (( "$#" )); do
    case "$1" in
        -p)
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

declare -r ISTIO_PRJ="${PROJECT_NAME}-istio-system"

# now install our control plane (operator we set up previously is listening for this service-mesh.yml file
# that represents the features of istio that we want turned on/off)
oc apply -f ${DEMO_HOME}/istiofiles/install/service-mesh.yaml -n $ISTIO_PRJ

echo "Waiting for Service Mesh Control Plane to be ready..."
oc wait --for=condition=Ready smcp/basic-install --timeout 6m -n $ISTIO_PRJ

# Policy checks are disabled by default.  We need to turn them on to allow the Security policy checks to work
# NOTE: Istio will eventually notice this change by itself.  No redeploy is necessary
oc get cm istio -n ${ISTIO_PRJ} -o yaml | sed "s/disablePolicyChecks: true/disablePolicyChecks: false/g" | oc apply -n ${ISTIO_PRJ} -f -

echo "done."
