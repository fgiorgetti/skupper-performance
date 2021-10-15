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
    skupper link status | grep -q 'is active' && echo "on-premise" || echo "cloud"
}

writeResults() {
    tool=$1; shift
    to=$1; shift
    tp=$1; shift
    
    # detecting source (op or cl)
    from="cl"
    skupper link status | grep -q 'is active' && from="op"
    
    # detecting destination (podip, lb, op, cl)
    if [[ ${to} =~ \. ]]; then
        dest=podip
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
    op_cl=`average "results/${tool}-op-cl"`

    cl_podip=`average "results/${tool}-cl-podip"`
    cl_lb=`average "results/${tool}-cl-lb"`
    cl_op=`average "results/${tool}-cl-op"`
    cl_cl=`average "results/${tool}-cl-cl"`
    echo Refreshing data file $dataFile
    cat << EOF > $dataFile
${tool}Data = [
  ['${tool^^} throughput (${tpunit})', 'pod ip', 'load balancer', 'on-premise (skupper)', 'cloud (skupper)'],
  ['on-premise', ${op_podip}, ${op_lb}, ${op_op}, ${op_cl}],
  ['cloud', ${cl_podip}, ${cl_lb}, ${cl_op}, ${cl_cl}],
]

${tool}Options = {
  chart: {
    title: 'Skupper - ${tool^^} performance numbers',
    subtitle: 'On-premise / Cloud (${protocol^^} adaptor)',
  }
}
EOF
}
