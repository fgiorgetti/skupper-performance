#!/bin/bash

. common.sh

runAmqp() {
    #
    # Running amqp tests
    #
    kubectl delete job/amqp-client
    waitNoPods amqp-client
    POD_IP=`kubectl get pods -l app=amqp-server -o json | jq -r .items[0].status.podIP`
    export AMQP_SERVER=${AMQP_SERVER:-${POD_IP}}

    echo
    echo "Running amqp tests ($AMQP_SERVER) from `runningFrom`"
    echo
    
    cat resources/amqp-client.yaml | envsubst | kubectl apply -f -
    
    waitJobCompleted amqp-client
    echo
    echo
    kubectl logs job/amqp-client
    tp=`kubectl logs job/amqp-client | grep 'messages/s' | awk '{print $(NF-1)}' | sed 's/,//g' | average`
    echo "AMQP Throughput to ${AMQP_SERVER}: ${tp} msgs/s"
    writeResults amqp "${AMQP_SERVER}" ${tp}
    
    echo
    echo
    echo
}

runAmqpAll() {
    # pod ip
    #runAmqp
    # lb
    #! isCloud && AMQP_SERVER=amqp-server runAmqp
    # op
    isCloud && AMQP_SERVER=amqp-skupper-onpremise runAmqp
    if ! isCloud && kubectl get svc amqp-server-cloud-lb; then
        # if resolving, proceed
        nslookup `kubectl get svc amqp-server-cloud-lb -o json | jq -r .spec.externalName`
        # cl_lb
        [[ $? -eq 0 ]] && AMQP_SERVER=amqp-server-cloud-lb runAmqp || echo -en "\n\nUnable to test against amqp-server-cloud-lb (not resolving)\n\n"
    fi
    # cl
    ! isCloud && AMQP_SERVER=amqp-skupper-cloud runAmqp
}

[[ $0 =~ run-amqp-tests.sh ]] && ( [[ -z ${AMQP_SERVER} ]] && runAmqpAll || runAmqp )
