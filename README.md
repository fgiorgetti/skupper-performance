# skupper-performance
Utilities to run performance tests using Skupper

## onpremise-cloud

Provides some shell scripts to automate the preparation of a Skupper
scenario that connects an on-premise (private) to a cloud (public) cluster.

It runs basic performance tests using:
* iPerf3
* Postgres (pgbench)
* HTTP (hey/nginx)

After test completes, it generates charts to help evaluating the results.
For more information, check the scenario documentation: [./onpremise-cloud/](./onpremise-cloud/README.md)