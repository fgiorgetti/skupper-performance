. common.sh

runIperfServer() {
    #
    # Running iperf3 server
    #
    echo
    echo Running iperf3 server
    echo
    kubectl delete deploy/iperf-server
    waitNoPods iperf-server
    kubectl apply  -f resources/iperf-server.yaml
    waitPodRunning iperf-server
    kubectl expose deployment iperf-server
}

runPostgresServer() {
    #
    # Running postgres server
    #
    echo
    echo "Running postgres server"
    echo
    
    kubectl delete -f resources/postgres-server.yaml
    waitNoPods postgres-server
    kubectl apply  -f resources/postgres-server.yaml
    waitPodRunning postgres-server
    kubectl expose deployment postgres-server
}

runHttpServer() {
    #
    # Running http 1 server (nginx)
    #
    echo
    echo "Running HTTP 1 server (nginx)"
    echo
    
    kubectl delete -f resources/http-server.yaml
    waitNoPods http-server
    kubectl apply  -f resources/http-server.yaml
    waitPodRunning http-server
    kubectl expose deployment http-server
}

${IPERF:-true} && runIperfServer
${POSTGRES:-true} && runPostgresServer
${HTTP:-true} && runHttpServer
