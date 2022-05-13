redisDataOnPremise = [
  ['REDIS throughput (gbps)', 'pod ip', 'load balancer', 'on-premise (skupper)', 'cloud (load balancer)', 'cloud (route)', 'cloud (skupper)'],
  ['From on-premise to', 0, 0, 0, 11514.4, 0, 4103.29],
]
redisDataCloud = [
  ['REDIS throughput (gbps)', 'pod ip', 'load balancer', 'on-premise (skupper)', 'cloud (load balancer)', 'cloud (route)', 'cloud (skupper)'],
  ['From cloud to', 0, 0, 4637.71, 0, 0, 0],
]
yMax = Math.max(...redisDataOnPremise[1].slice(1), ...redisDataCloud[1].slice(1))
redisOptionsOnPremise = {
  title: 'From On-Premise cluster',
  bar: {
    groupWidth: '100%'
  },
  vAxis: {
    minValue: 0,
    maxValue: yMax,
  },
  colors: ['blue', 'green'],
  legend: {
    position: 'bottom',
    textStyle: {
        fontSize: 14,
    }
  }
}
redisOptionsCloud = {
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
