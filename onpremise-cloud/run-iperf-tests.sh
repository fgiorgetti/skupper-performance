#!/bin/bash

. common.sh

runIperf() {
    #
    # Running iperf3 tests
    #
    kubectl delete job/iperf-client
    waitNoPods iperf-client
    POD_IP=`kubectl get pods -l app=iperf-server -o json | jq -r .items[0].status.podIP`
    export IPERF_SERVER=${IPERF_SERVER:-${POD_IP}}

    echo
    echo "Running iperf3 tests ($IPERF_SERVER) from `runningFrom`"
    echo
    
    cat resources/iperf-client.yaml | envsubst | kubectl apply -f -
    
    waitJobCompleted iperf-client
    echo
    echo
    kubectl logs job/iperf-client
    tp=`kubectl logs job/iperf-client | egrep '(sender|receiver)$' | awk '{print $7}'`
    echo "iPerf3 Throughput to ${IPERF_SERVER}: ${tp} gbps"
    writeResults iperf "${IPERF_SERVER}" ${tp}
    
    echo
    echo
    echo
}

runIperfAll() {
    # pod ip
    runIperf
    # lb
    IPERF_SERVER=iperf-server runIperf
    # op
    IPERF_SERVER=iperf-skupper-onpremise runIperf
    # cl
    IPERF_SERVER=iperf-skupper-cloud runIperf
}

[[ $0 =~ run-iperf-tests.sh ]] && runIperfAll
