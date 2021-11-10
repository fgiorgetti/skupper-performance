#!/bin/bash

. common.sh

runRedis() {
    #
    # Running redis tests
    #
    kubectl delete job/redis-client
    waitNoPods redis-client
    POD_IP=`kubectl get pods -l app=redis-server -o json | jq -r .items[0].status.podIP`
    export REDIS_SERVER=${REDIS_SERVER:-${POD_IP}}

    echo
    echo "Running redis tests ($REDIS_SERVER) from `runningFrom`"
    echo
    
    cat resources/redis-client.yaml | envsubst | kubectl apply -f -
    
    waitJobCompleted redis-client
    echo
    echo
    tp=`kubectl logs job/redis-client | awk -F 'requests per second' '{print $1}' | awk '{print $NF}' | average`
    echo "Redis Throughput to ${REDIS_SERVER}: ${tp} rps"
    writeResults redis "${REDIS_SERVER}" ${tp}
    
    echo
    echo
    echo
}

runRedisAll() {
    # pod ip
    #runRedis
    # lb
    #! isCloud && REDIS_SERVER=redis-server runRedis
    # op
    isCloud && REDIS_SERVER=redis-skupper-onpremise runRedis
    if ! isCloud && kubectl get svc redis-server-cloud-lb; then
        # if resolving, proceed
        nslookup `kubectl get svc redis-server-cloud-lb -o json | jq -r .spec.externalName`
        # cl_lb
        [[ $? -eq 0 ]] && REDIS_SERVER=redis-server-cloud-lb runRedis || echo -en "\n\nUnable to test against redis-server-cloud-lb (not resolving)\n\n"
    fi
    # cl
    ! isCloud && REDIS_SERVER=redis-skupper-cloud runRedis
}

[[ $0 =~ run-redis-tests.sh ]] && ( [[ -z ${REDIS_SERVER} ]] && runRedisAll || runRedis )
