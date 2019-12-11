# For Use with RHPDS using these instructions: https://learning.redhat.com/mod/scorm/player.php?a=1220&currentorg=&scoid=2877&sesskey=AH5CWj7OL9&display=popup&mode=normal

# MANUAL STEPS using Operator Hub, apply the service mesh operator to all projects

SCRIPT_DIR=$(dirname $0)
DEMO_HOME=$SCRIPT_DIR/..

# now install our control plane (operator we set up previously is listening for this service-mesh.yml file
# that represents the features of istio that we want turned on/off)
oc apply -f ${SCRIPT_DIR}/service-mesh.yaml -n istio-system

# install the ServiceMeshMemoryRoll resource which will 
# define which projects will participate in the service mesh (and thus will have sidecar injected into them)
oc apply -f ${SCRIPT_DIR}/service-mesh-roll.yaml -n istio-system

printf "Move on to the next script once all the following pods have been created:
grafana-b67df64b6-dwx44                
istio-citadel-79979464d-qh6fn          
istio-egressgateway-7d897695c4-p6jbj   
istio-galley-6bb46858c5-k6z2w          
istio-ingressgateway-8465bbf788-phcjn  
istio-pilot-54b65495c4-ks46p           
istio-policy-5fc74b8697-cldbw          
istio-sidecar-injector-65cd4c8c6f-8nq4k
istio-telemetry-69cb778b9-j4xhw        
jaeger-57776787bc-j8rq8                
kiali-6d6f9cf658-sthwl                 
prometheus-b8bdc6b77-kpgtn             "

oc get pods -n istio-system -w
