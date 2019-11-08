# For Use with RHPDS using these instructions: https://learning.redhat.com/mod/scorm/player.php?a=1220&currentorg=&scoid=2877&sesskey=AH5CWj7OL9&display=popup&mode=normal

# MANUAL STEPS using Operator Hub
# First install the Elasticsearch operator
# Then the Jaeger Operator
# Then the Kiali Operator

# make your own control mesh operator
oc adm new-project istio-operator --display-name="Service Mesh Operator"
oc project istio-operator
oc apply -n istio-operator -f deploy/servicemesh-operator.yaml

read -n 1 -p "Press 'y' when service operator deployment is complete: " COMPLETE
if [ "$COMPLETE" != "y" ]; then 
    printf "\nUser indicated installation was not successful.  Aborting...\n"
    exit 1
fi

# now install our control plane (operator we set up previously is listening for this service-mesh.yml file
# that represents the features of istio that we want turned on/off)
oc adm new-project istio-system --display-name="Service Mesh System"
oc apply -f service-mesh.yml -n istio-system

# install the ServiceMeshMemoryRoll resource which will 
# define which projects will participate in the service mesh (and thus will have sidecar injected into them)
oc apply -f service-mesh-roll.yml -n istio-system