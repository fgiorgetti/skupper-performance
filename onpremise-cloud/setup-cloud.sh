#!/bin/bash

. common.sh

skupper delete
rm cloud.token.yaml

skupper init --console-password admin
#skupper init --console-password admin --router-cpu '2.0'
skupper token create --uses 100 --expiry 48h cloud.token.yaml
waitPodRunning skupper-service-controller

./run-servers.sh

skupper service create iperf-skupper-cloud 5201
skupper service bind iperf-skupper-cloud deployment iperf-server
skupper service create postgres-skupper-cloud 5432
skupper service bind postgres-skupper-cloud deployment postgres-server
skupper service create amqp-skupper-cloud 5672
skupper service bind amqp-skupper-cloud deployment amqp-server
skupper service create redis-skupper-cloud 6379
skupper service bind redis-skupper-cloud deployment redis-server
skupper service create http-skupper-cloud 8080 --mapping http
skupper service bind http-skupper-cloud deployment http-server
