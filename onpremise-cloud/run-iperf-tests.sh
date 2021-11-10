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
    tp=`kubectl logs job/iperf-client | egrep 'SUM.*(sender|receiver)$' | awk -F 'Gbits/sec' '{print $1}' | awk '{print $NF}'`
    if [[ "${tp}" = "" ]]; then
        tp=`kubectl logs job/iperf-client | egrep '(sender|receiver)$' | awk -F 'Gbits/sec' '{print $1}' | awk '{print $NF}'`
    fi
    tp=`echo "${tp}" | average`
    echo "iPerf3 Throughput to ${IPERF_SERVER}: ${tp} gbps"
    writeResults iperf "${IPERF_SERVER}" ${tp}
    
    echo
    echo
    echo
}

runIperfAll() {
    # pod ip
    #runIperf
    # lb
    #! isCloud && IPERF_SERVER=iperf-server runIperf
    # op
    isCloud && IPERF_SERVER=iperf-skupper-onpremise runIperf
    if ! isCloud && kubectl get svc iperf-server-cloud-lb; then
        # if resolving, proceed
        nslookup `kubectl get svc iperf-server-cloud-lb -o json | jq -r .spec.externalName`
        # cl_lb
        [[ $? -eq 0 ]] && IPERF_SERVER=iperf-server-cloud-lb runIperf || echo -en "\n\nUnable to test against iperf-server-cloud-lb (not resolving)\n\n"
    fi
    # cl
    ! isCloud && IPERF_SERVER=iperf-skupper-cloud runIperf
}

[[ $0 =~ run-iperf-tests.sh ]] && ( [[ -z ${IPERF_SERVER} ]] && runIperfAll || runIperf )
