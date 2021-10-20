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
    tp=`kubectl logs job/iperf-client | egrep 'SUM.*(sender|receiver)$' | awk '{print $6}'`
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
    if ! isCloud && kubectl get svc iperf-server-cloud-lb; then
        # if resolving, proceed
        nslookup `kubectl get svc iperf-server-cloud-lb -o json | jq -r .spec.externalName`
        # cl_lb
        [[ $? -eq 0 ]] && IPERF_SERVER=iperf-server-cloud-lb runIperf || echo -en "\n\nUnable to test against iperf-server-cloud-lb (not resolving)\n\n"
    fi
    # cl
    IPERF_SERVER=iperf-skupper-cloud runIperf
}

[[ $0 =~ run-iperf-tests.sh ]] && ( [[ -z ${IPERF_SERVER} ]] && runIperfAll || runIperf )
