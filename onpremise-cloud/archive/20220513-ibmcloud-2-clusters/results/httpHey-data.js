httpHeyDataOnPremise = [
  ['HTTPHEY throughput (gbps)', 'pod ip', 'load balancer', 'on-premise (skupper)', 'cloud (load balancer)', 'cloud (route)', 'cloud (skupper)'],
  ['From on-premise to', 0, 0, 0, 5984.12, 4460.64, 1956.91],
]
httpHeyDataCloud = [
  ['HTTPHEY throughput (gbps)', 'pod ip', 'load balancer', 'on-premise (skupper)', 'cloud (load balancer)', 'cloud (route)', 'cloud (skupper)'],
  ['From cloud to', 0, 0, 1453.7, 0, 0, 0],
]
yMax = Math.max(...httpHeyDataOnPremise[1].slice(1), ...httpHeyDataCloud[1].slice(1))
httpHeyOptionsOnPremise = {
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
httpHeyOptionsCloud = {
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
