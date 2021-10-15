# onpremise-cloud

## Description

Provides some shell scripts to automate the preparation of a Skupper
scenario that connects an on-premise (private) to a cloud (public) cluster.

It runs basic performance tests using:
* iPerf3
* Postgres (pgbench)
* HTTP (hey/nginx)

After test completes, it generates charts to help evaluating the results.

## Topology

```
 --------------------------------------------                   ---------------------------------------------                                                                          
|                                            |                 |                                             |                                                                         
|                 On-Premise                 |                 |                   Cloud                     |                                                                         
|                                            |                 |                                             |                                                                         
|   --------------------------------------   |                 |   ---------------------------------------   |                                                                         
|  |               Services               |  |                 |  |               Services                |  |                                                                         
|  | * iperf-server (direct)              |  |                 |  | * iperf-server (direct)               |  |                                                                         
|  | * iperf-skupper-onpremise (local)    |  |                 |  | * iperf-skupper-onpremise (remote)    |  |                                                                         
|  | * iperf-skupper-cloud (remote)       |  |      Link       |  | * iperf-skupper-cloud (local)         |  |                                                                         
|  | * postgres-server (direct)           |  |  ============>  |  | * postgres-server (direct)            |  |                                                                         
|  | * postgres-skupper-onpremise (local) |  |                 |  | * postgres-skupper-onpremise (remote) |  |                                                                         
|  | * postgres-skupper-cloud (remote)    |  |                 |  | * postgres-skupper-cloud (local)      |  |                                                                         
|  | * http-server (direct)               |  |                 |  | * http-server (direct)                |  |                                                                         
|  | * http-skupper-onpremise (local)     |  |                 |  | * http-skupper-onpremise (remote)     |  |                                                                         
|  | * http-skupper-cloud (remote)        |  |                 |  | * http-skupper-cloud (local)          |  |                                                                         
|   --------------------------------------   |                 |   ---------------------------------------   |                                                                         
|                                            |                 |                                             |                                                                         
 --------------------------------------------                   ---------------------------------------------                                                                          

```

## Pre-requisites

* skupper (binary)
* kubectl (binary)
* namespaces created in the on-premise (private) and cloud (public) clusters

## Setting up the scenario

Open a terminal with access to your `on-premise` cluster. Make sure that the
current namespace is defined correctly:

```
kubectl config get-contexts $(kubectl config current-context)
```

If the namespace is not set correctly, you can update it using:

```
kubectl config set-context --current --namespace=<desired_namespace>
```

Then open a terminal with access to your `cloud` cluster. Same as before, make sure
the current namespace is defined correctly.

In the `cloud` cluster terminal, run:

```
./setup-cloud.sh
```

Then back to the `on-premise` terminal, run:

```
./setup-onpremise.sh
```

You can run: `skupper status` in the `on-premise` cluster till you see something similar to:

```
Skupper is enabled for namespace "on-premise" in interior mode. It is connected to 1 other site. It has 6 exposed services.
The site console url is:  https://10.110.112.191:8080
The credentials for internal console-auth mode are held in secret: 'skupper-console-users'
```

If you are getting problems setting up this scenario, please report an issue.

## Running the tests

Once the scenario is prepared, you can run the tests.
There are several scripts to run the tests:

* run-tests.sh (run all the tests: iperf, postgres and http)
* run-iperf-tests.sh
* run-postgres-tests.sh
* run-http-tests.sh

It is recommended to run the `./run-tests.sh` initially, as it will initialize the results.
You can run any of the tests as many times as you want. Everytime you re-run a test, it will
store its throughtput, recalculate the average throughput and update the results.

## Visualizing the results

You can open the `charts.html` using your preferrable web browser. In example: `firefox ./charts.html` or
`google-chrome ./charts.html`.
