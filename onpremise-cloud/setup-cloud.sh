#!/bin/bash

. common.sh

skupper delete
rm cloud.token.yaml

skupper init --console-password admin --router-cpu '2.0'
skupper token create --uses 100 cloud.token.yaml
waitPodRunning skupper-service-controller

./run-servers.sh

skupper service create iperf-skupper-cloud 5201
skupper service bind iperf-skupper-cloud deployment iperf-server
skupper service create postgres-skupper-cloud 5432
skupper service bind postgres-skupper-cloud deployment postgres-server
skupper service create http-skupper-cloud 8080 --mapping http
skupper service bind http-skupper-cloud deployment http-server
