#!/bin/bash

. common.sh

getExternalIP() {
    service=$1
    rm ${service}-cloud.hostname
    if isCloud && isOpenShift; then
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
    isCloud && getExternalIP iperf-server
}

runRedisServer() {
    #
    # Running redis server
    #
    echo
    echo Running redis server
    echo
    kubectl delete svc redis-server --now
    kubectl delete deploy/redis-server
    waitNoPods redis-server
    kubectl apply  -f resources/redis-server.yaml
    waitPodRunning redis-server
    # prevent client communication error
    kubectl exec deploy/redis-server -- redis-cli config set stop-writes-on-bgsave-error no
    exposeSvc redis-server
    isCloud && getExternalIP redis-server
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
    isCloud && getExternalIP postgres-server
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
    isCloud && rm -f http-server-cloud.route
    isOpenShift && isCloud && kubectl get route http-server -o json | jq -r '.spec.host' > http-server-cloud.route
    isCloud && getExternalIP http-server
}

runAmqpServer() {
    #
    # Running amqp server (qdrouterd)
    #
    echo
    echo "Running amqp server"
    echo
    
    kubectl delete svc amqp-server --now
    kubectl delete -f resources/amqp-server.yaml
    waitNoPods amqp-server
    kubectl apply  -f resources/amqp-server.yaml
    waitPodRunning amqp-server
    exposeSvc amqp-server
    isCloud && getExternalIP amqp-server
}

${IPERF:-true} && runIperfServer
${POSTGRES:-true} && runPostgresServer
${HTTP:-true} && runHttpServer
${AMQP:-true} && runAmqpServer
${REDIS:-true} && runRedisServer
