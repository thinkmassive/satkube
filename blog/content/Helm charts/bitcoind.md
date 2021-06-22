---
title: "Bitcoin Core"
date: 2021-06-20T12:00:00Z
draft: false
weight: 10
summary: "An overview of the 'bitcoind' helm chart from GaloyMoney"

---

Using [GaloyMoney/charts](https://github.com/GaloyMoney/charts/)

## bitcoind Installation

The following commands can be executed by running `03-helm-bitcoind.sh`

```bash
# Define namespace
NS=satkube

# Define values.yaml file (review and adjust as desired before proceeding)
VALUES=$(pwd)/helm_values/bitcoind/values.yaml

# Change to chart dir
cd charts/galoy/charts/bitcoind

# Install via helm
helm install bitcoind . -f $VALUES -n $NS
```

Follow the NOTES output to quickly verify RPC connectivity, then continue watching the logs in Kibana.

```bash
# Quick test to verify bitcoind RPC:
BITCOIND_POD=$(kubectl get pod -n default -l "app.kubernetes.io/name=bitcoind" -o jsonpath="{ .items[0].metadata.name }"
kubectl port-forward -n default $BITCOIND_POD

# need to wait for active to catch up to headers
kubectl exec -it bitcoind-0 -c bitcoind -- bitcoin-cli getchaintips
```

### bitcoind Post-install Questions

  - Q: How could I speed up initial block download (IBD)?
    - A: The `bitcoin.conf` file is stored as a [ConfigMap](https://github.com/GaloyMoney/charts/blob/main/charts/bitcoind/templates/configmap.yaml), and custom values are read from dict `bitcoindCustomConfig`, which is defined near the bottom of values.yaml
      - Next time I would temporarily increase the following values, which are undefined in the chart:
        - DB cache: `dbcache=4096` (default is 450 MiB)
        - Verification thread count: `par=2` (default is auto, so 1 less than total CPU cores)
      - For details on other parameters, check out Lopp's [Bitcoin Core Config Generator](https://jlopp.github.io/bitcoin-core-config-generator/)
