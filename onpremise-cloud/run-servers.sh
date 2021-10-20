#!/bin/bash

. common.sh

getExternalIP() {
    service=$1
    if isCloud; then
        rm ${service}-cloud.hostname
        cloud_hostname=""
        attempt=0
        while [[ -z "${cloud_hostname}" ]]; do
            let attempt++
            cloud_hostname=`kubectl get svc ${service} -o json | jq -r '.status.loadBalancer.ingress[0].hostname | select (.!=null)'`
            [[ ${attempt} -gt 10 ]] && echo "Unable to get external IP" && break
            echo "waiting for loadbalancer external ip"
            sleep 6
        done
        [[ -n ${cloud_hostname} ]] && echo -n ${cloud_hostname} > ${service}-cloud.hostname
    fi
}

exposeSvc() {
    deployment=$1
    svcType="ClusterIP"
    isCloud && svcType="LoadBalancer"
    kubectl expose deployment ${deployment} --type=${svcType}
    ! isCloud && test -f ${deployment}-cloud.hostname && (kubectl delete svc ${deployment}-cloud-lb --now; kubectl create service externalname ${deployment}-cloud-lb --external-name `cat ${deployment}-cloud.hostname`)
}

runIperfServer() {
    #
    # Running iperf3 server
    #
    echo
    echo Running iperf3 server
    echo
    kubectl delete svc iperf-server --now
    kubectl delete deploy/iperf-server
    waitNoPods iperf-server
    kubectl apply  -f resources/iperf-server.yaml
    waitPodRunning iperf-server
    exposeSvc iperf-server
    getExternalIP iperf-server
}

runPostgresServer() {
    #
    # Running postgres server
    #
    echo
    echo "Running postgres server"
    echo
    
    kubectl delete svc postgres-server --now
    kubectl delete -f resources/postgres-server.yaml
    waitNoPods postgres-server
    kubectl apply  -f resources/postgres-server.yaml
    waitPodRunning postgres-server
    exposeSvc postgres-server
    getExternalIP postgres-server
}

runHttpServer() {
    #
    # Running http 1 server (nginx)
    #
    echo
    echo "Running HTTP 1 server (nginx)"
    echo
    
    kubectl delete svc http-server --now
    kubectl delete -f resources/http-server.yaml
    waitNoPods http-server
    kubectl apply  -f resources/http-server.yaml
    waitPodRunning http-server
    exposeSvc http-server
    isOpenShift && isCloud && ( oc delete route http-server; oc expose service http-server)
    isOpenShift && isCloud && kubectl get route http-server -o json | jq -r '.spec.host' > http-server-cloud.route
    getExternalIP http-server
}

${IPERF:-true} && runIperfServer
${POSTGRES:-true} && runPostgresServer
${HTTP:-true} && runHttpServer
