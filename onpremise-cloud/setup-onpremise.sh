. common.sh

[[ ! -f cloud.token.yaml ]] && echo "Run the skupper-cloud.sh first" && exit 1
skupper delete

./run-servers.sh

skupper init --console-password admin
waitPodRunning skupper-service-controller

skupper service create iperf-skupper-onpremise 5201
skupper service bind iperf-skupper-onpremise deployment iperf-server
skupper service create postgres-skupper-onpremise 5432
skupper service bind postgres-skupper-onpremise deployment postgres-server
skupper service create http-skupper-onpremise 8080 --mapping http
skupper service bind http-skupper-onpremise deployment http-server

skupper link create cloud.token.yaml
