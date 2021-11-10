#!/bin/bash

. common.sh

runHttp() {
    client=${1:-hey}

    #
    # Running http 1 tests using provided client
    #
    kubectl delete -f resources/http-client-${client}.yaml
    waitNoPods http-client-${client}
    
    POD_IP=`kubectl get pods -l app=http-server -o json | jq -r .items[0].status.podIP`
    export HTTP_SERVER="${HTTP_SERVER:-${POD_IP}}"
    export HTTP_PORT="${HTTP_PORT:-8080}"

    echo
    echo "Running HTTP 1 tests (${HTTP_SERVER}) using ${client} from `runningFrom`"
    echo
    
    cat resources/http-client-${client}.yaml | envsubst | kubectl apply -f -
    
    waitJobCompleted http-client-${client}
    echo
    echo
    kubectl logs job/http-client-${client}
    tp=`kubectl logs job/http-client-${client} | grep 'Requests/sec:' | awk '{print $NF}'`
    echo "HTTP Throughput to ${HTTP_SERVER}: ${tp} requests/s"
    writeResults http${client^} "${HTTP_SERVER}" ${tp}
    
    echo
    echo
    echo
}

runHttpAll() {
    # pod ip
    #runHttp hey
    #runHttp wrk
    # lb
    #! isCloud && HTTP_SERVER=http-server runHttp hey
    #! isCloud && HTTP_SERVER=http-server runHttp wrk
    # op
    isCloud && HTTP_SERVER=http-skupper-onpremise runHttp hey
    isCloud && HTTP_SERVER=http-skupper-onpremise runHttp wrk
    if ! isCloud && kubectl get svc http-server-cloud-lb; then
        # if resolving, proceed
        nslookup `kubectl get svc http-server-cloud-lb -o json | jq -r .spec.externalName`
        # cl_lb
        lookup_valid=$?
        [[ ${lookup_valid} -eq 0 ]] && HTTP_SERVER=http-server-cloud-lb runHttp hey || echo -n "\n\nUnable to test against http-server-cloud-lb (not resolving)\n\n"
        [[ ${lookup_valid} -eq 0 ]] && HTTP_SERVER=http-server-cloud-lb runHttp wrk || echo -n "\n\nUnable to test against http-server-cloud-lb (not resolving)\n\n"
    fi
    # cl (route)
    if ! isCloud && test -f http-server-cloud.route; then
        HTTP_SERVER=`cat http-server-cloud.route` HTTP_PORT=80 runHttp hey
        HTTP_SERVER=`cat http-server-cloud.route` HTTP_PORT=80 runHttp wrk
    fi
    # cl
    ! isCloud && HTTP_SERVER=http-skupper-cloud HTTP_PORT=8080 runHttp hey
    ! isCloud && HTTP_SERVER=http-skupper-cloud HTTP_PORT=8080 runHttp wrk
}

[[ $0 =~ run-http-tests.sh ]] && ( [[ -z ${HTTP_SERVER} ]] && runHttpAll || runHttp )
