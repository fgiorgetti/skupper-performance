#!/bin/bash

. common.sh

runPostgres() {
    #
    # Running postgres tests
    #
    kubectl delete -f resources/postgres-client.yaml
    waitNoPods postgres-client
    POD_IP=`kubectl get pods -l app=postgres-server -o json | jq -r .items[0].status.podIP`
    export POSTGRES_SERVER="${POSTGRES_SERVER:-${POD_IP}}"

    echo
    echo "Running postgres tests (${POSTGRES_SERVER}) from `runningFrom`"
    echo
    
    cat resources/postgres-client.yaml | envsubst | kubectl apply -f -
    
    waitJobCompleted postgres-client
    echo
    echo
    kubectl logs job/postgres-client
    tp=`kubectl logs job/postgres-client | egrep '^tps =' | awk '{print $3}'`
    echo "Postgres Throughput to ${POSTGRES_SERVER}: ${tp} tps"
    writeResults postgres "${POSTGRES_SERVER}" ${tp}

    
    echo
    echo
    echo
}

runPostgresAll() {
    # pod ip
    #runPostgres
    # lb
    #! isCloud && POSTGRES_SERVER=postgres-server runPostgres
    # op
    isCloud && POSTGRES_SERVER=postgres-skupper-onpremise runPostgres
    if ! isCloud && kubectl get svc postgres-server-cloud-lb; then
        # if resolving, proceed
        nslookup `kubectl get svc postgres-server-cloud-lb -o json | jq -r .spec.externalName`
        # cl_lb
        [[ $? -eq 0 ]] && POSTGRES_SERVER=postgres-server-cloud-lb runPostgres || echo -en "\n\nUnable to test against postgres-server-cloud-lb (not resolving)\n\n"
    fi
    # cl
    ! isCloud && POSTGRES_SERVER=postgres-skupper-cloud runPostgres
}

[[ $0 =~ run-postgres-tests.sh ]] && ( [[ -z ${POSTGRES_SERVER} ]] && runPostgresAll || runPostgres )
