httpWrkDataOnPremise = [
  ['HTTPWRK throughput (gbps)', 'pod ip', 'load balancer', 'on-premise (skupper)', 'cloud (load balancer)', 'cloud (route)', 'cloud (skupper)'],
  ['From on-premise to', 0, 0, 0, 3927.74, 3267.55, 1204.46],
]
httpWrkDataCloud = [
  ['HTTPWRK throughput (gbps)', 'pod ip', 'load balancer', 'on-premise (skupper)', 'cloud (load balancer)', 'cloud (route)', 'cloud (skupper)'],
  ['From cloud to', 0, 0, 1357.22, 0, 0, 0],
]
yMax = Math.max(...httpWrkDataOnPremise[1].slice(1), ...httpWrkDataCloud[1].slice(1))
httpWrkOptionsOnPremise = {
  title: 'From On-Premise cluster',
  bar: {
    groupWidth: '100%'
  },
  vAxis: {
    minValue: 0,
    maxValue: yMax,
  },
  colors: ['blue', 'red', 'green'],
  legend: {
    position: 'bottom',
    textStyle: {
        fontSize: 14,
    }
  }
}
httpWrkOptionsCloud = {
  title: 'From Cloud cluster',
  bar: {
    groupWidth: '100%'
  },
  vAxis: {
    minValue: 0,
    maxValue: yMax,
  },
  colors: ['green'],
  legend: {
    position: 'bottom',
    textStyle: {
        fontSize: 14,
    }
  }
}
