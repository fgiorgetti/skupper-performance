#!/bin/bash

waitPodRunning() {
    while ! kubectl get pod | grep -q "$1.*Running"; do echo Waiting $1 running; sleep 1; done
}

waitNoPods() {
    while kubectl get pod | grep -q "$1"; do echo Waiting $1 removed; sleep 1; done
}

waitJobCompleted() {
    attempt=0
    while ! kubectl get pod | grep -q "$1.*Completed"; do echo Waiting $1 completed; sleep 1; attempt=$((attempt+1)); [ $attempt -gt 60 ] && break; done
}

average() {
    file=$1; shift
    [[ ! -f ${file} ]] && echo 0 || cat $file | awk 'BEGIN{sum=0; c=0} {sum+=$1;c++} END{print sum/c}'
}

runningFrom() {
    [[ `kubectl get -o name secret -l 'skupper.io/type=token-claim-record' | wc -l` -gt 0 ]] && echo cloud || echo on-premise
}

isCloud() {
    [[ `runningFrom` = "cloud" ]] && true || false
}

isOpenShift() {
    kubectl api-resources | grep -q route.openshift.io && true || false
}
writeResults() {
    tool=$1; shift
    to=$1; shift
    tp=$1; shift
    
    # detecting source (op or cl)
    from="cl"
    skupper link status | grep -q 'is active' && from="op"
    
    # detecting destination (podip, lb, op, cl)
    if [[ ${to} =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        dest=podip
    elif [[ ${to} =~ \. ]]; then
        dest=cl-route
    elif [[ ${to} =~ -cloud-lb ]]; then
        dest=cl-lb
    elif [[ ${to} =~ -server ]]; then
        dest=lb
    elif [[ ${to} =~ -onpremise ]]; then
        dest=op
    else
        dest=cl
    fi

    # determining tpunit and protocol
    protocol="tcp"
    tpunit="gbps"
    case $tool in
        postgres)
            tpunit="tps"
        ;;
        http)
            tpunit="requests/s"
            protocol="http"
        ;;
    esac

    file="results/${tool}-${from}-${dest}"
    dataFile="results/${tool}-data.js"
    [[ ! -d results ]] && mkdir results
    echo Writing results to $file
    echo $tp >> $file

    # refreshing data file
    op_podip=`average "results/${tool}-op-podip"`
    op_lb=`average "results/${tool}-op-lb"`
    op_op=`average "results/${tool}-op-op"`
    op_cl_lb=0
    [[ -f results/${tool}-op-cl-lb ]] && op_cl_lb=`average "results/${tool}-op-cl-lb"`
    op_cl_route=0
    [[ ${tool} = "http" ]] && op_cl_route=`average "results/${tool}-op-cl-route"`
    op_cl=`average "results/${tool}-op-cl"`

    cl_podip=`average "results/${tool}-cl-podip"`
    cl_lb=`average "results/${tool}-cl-lb"`
    cl_op=`average "results/${tool}-cl-op"`
    cl_cl_route=0
    [[ ${tool} = "http" ]] && cl_cl_route=`average "results/${tool}-cl-cl-route"`
    cl_cl=`average "results/${tool}-cl-cl"`
    echo Refreshing data file $dataFile
    cat << EOF > $dataFile
${tool}DataOnPremise = [
  ['${tool^^} throughput (${tpunit})', 'on-premise (skupper)', 'cloud (k8s lb)', 'cloud (route)', 'cloud (skupper)'],
  ['From on-premise to', ${op_op}, ${op_cl_lb}, ${op_cl_route}, ${op_cl}],
]
${tool}DataCloud = [
  ['${tool^^} throughput (${tpunit})', 'on-premise (skupper)', 'cloud (skupper)'],
  ['From cloud to', ${cl_op}, ${cl_cl}],
]
iperfOptionsOnPremise = {
  title: 'From On-Premise cluster',
  bar: {
    groupWidth: '100%'
  },
  legend: {
    position: 'bottom',
    textStyle: {
        fontSize: 14,
    }
  }
}
iperfOptionsCloud = {
  title: 'From Cloud cluster',
  bar: {
    groupWidth: '100%'
  },
  legend: {
    position: 'bottom',
    textStyle: {
        fontSize: 14,
    }
  }
}

${tool}DataFull = [
  ['${tool^^} throughput (${tpunit})', 'pod ip', 'load balancer', 'on-premise (skupper)', 'cloud (load balancer)', 'cloud (route)', 'cloud (skupper)'],
  ['on-premise', ${op_podip}, ${op_lb}, ${op_op}, ${op_cl_lb}, ${op_cl_route}, ${op_cl}],
  ['cloud', ${cl_podip}, ${cl_lb}, ${cl_op}, ${cl_lb}, ${cl_cl_route}, ${cl_cl}],
]

${tool}OptionsFull = {
  title: 'Skupper - ${tool^^} performance numbers (${tpunit}) - ${protocol^^}',
  bar: {
    groupWidth: '100%'
  },
  chart: {
    title: 'Skupper - ${tool^^} performance numbers',
    subtitle: 'On-premise / Cloud (${protocol^^} adaptor)',
  }
}
EOF
}
