. common.sh

runHttp() {
    #
    # Running http 1 tests
    #
    kubectl delete -f resources/http-client.yaml
    waitNoPods http-client
    
    POD_IP=`kubectl get pods -l app=http-server -o json | jq -r .items[0].status.podIP`
    export HTTP_SERVER="${HTTP_SERVER:-${POD_IP}}"

    echo
    echo "Running HTTP 1 tests (${HTTP_SERVER}) from `runningFrom`"
    echo
    
    cat resources/http-client.yaml | envsubst | kubectl apply -f -
    
    waitJobCompleted http-client
    echo
    echo
    kubectl logs job/http-client
    tp=`kubectl logs job/http-client | grep 'Requests/sec:' | awk '{print $NF}'`
    echo "HTTP Throughput to ${HTTP_SERVER}: ${tp} requests/s"
    writeResults http "${HTTP_SERVER}" ${tp}
    
    echo
    echo
    echo
}

runHttpAll() {
    # pod ip
    runHttp
    # lb
    HTTP_SERVER=http-server runHttp
    # op
    HTTP_SERVER=http-skupper-onpremise runHttp
    # cl
    HTTP_SERVER=http-skupper-cloud runHttp
}

[[ $0 =~ run-http-tests.sh ]] && runHttpAll
