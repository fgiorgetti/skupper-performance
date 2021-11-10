#!/bin/bash

. common.sh
. run-iperf-tests.sh
. run-postgres-tests.sh
. run-http-tests.sh
. run-amqp-tests.sh
. run-redis-tests.sh

${IPERF:-true} && runIperfAll
${POSTGRES:-true} && runPostgresAll
${HTTP:-true} && runHttpAll
${AMQP:-true} && runAmqpAll
${REDIS:-true} && runRedisAll
