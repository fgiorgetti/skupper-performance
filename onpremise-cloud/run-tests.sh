. common.sh
. run-iperf-tests.sh
. run-postgres-tests.sh
. run-http-tests.sh

${IPERF:-true} && runIperfAll
${POSTGRES:-true} && runPostgresAll
${HTTP:-true} && runHttpAll
