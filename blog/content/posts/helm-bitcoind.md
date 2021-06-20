---
title: "bitcoind helm chart"
date: 2021-06-20T12:00:00Z
draft: false
summary: "An overview of the 'bitcoind' helm chart from GaloyMoney"

---

Using [GaloyMoney/charts](https://github.com/GaloyMoney/charts/). First I'll describe the bitcoind install and kick it off. While waiting for initial block download (IBD), I'll review the existing hardening that's been done using these charts.

## bitcoind Installation

To prepare for bitcoind install, change dir to `charts/bitcoind`, then review values.yaml and determine if any are likely to need updating just to get the pods running. Here are my initial modifications:

  - Uncomment the annotations (and remove `{}`) to enable nginx-ingress (provided by BKPR)
  - Set the hostname: `bitcoind.citadelic.org`
  - Uncomment the `tls` section (and remove `{}`) to enable certificate generation
  - Uncomment limits+requests, set based on EC2 instance size (I used `cpu: 1900m` `memory: 5120Mi`)
  - Reduce `maxReplicas` as a failsafe (leave autoscaling `enabled: false`)

Now install bitcoind via helm:

```bash
cd galoy/charts/charts/bitcoind
helm install bitcoind . -f values.yaml
```

I followed the Notes output to quickly verify RPC connectivity, then continued watching the logs in Kibana.

```bash
# Quick test to verify bitcoind RPC:
BITCOIND_POD=$(kubectl get pod -n default -l "app.kubernetes.io/name=bitcoind" -o jsonpath="{ .items[0].metadata.name }"
kubectl port-forward -n default $BITCOIND_POD

CHAINTIPS_JSON="$(kubectl exec -it bitcoind-0 -c bitcoind -- bitcoin-cli getchaintips)"
CHAINTIP_ACTIVE=$(jq .[1].height <(echo $CHAINTIPS_JSON))
CHAINTIP_HEADERS=$(jq .[0].height <(echo $CHAINTIPS_JSON))

while $CHAINTIP_ACTIVE != $CHAINTIP_HEADERS; do
  echo "waiting for $CHAINTIP_ACTIVE to reach $CHAINTIP_HEADERS"
  sleep 60
  CHAINTIPS_JSON="$(kubectl exec -it bitcoind-0 -c bitcoind -- bitcoin-cli getchaintips)"
  CHAINTIP_ACTIVE=$(jq .[1].height <(echo $CHAINTIPS_JSON))
  CHAINTIP_HEADERS=$(jq .[0].height <(echo $CHAINTIPS_JSON))
done
```

### bitcoind Post-install Questions

After letting the sync run for a few hours, I had a few questions to answer before provisioning additional nodes (or re-provisioning the existing one). Some were easy enough to answer, so I included those here. Hopefully I can answer the rest in a future post.

  - Q: How could I speed up initial block download (IBD)?
    - A: The `bitcoin.conf` file is stored as a [ConfigMap](https://github.com/GaloyMoney/charts/blob/main/charts/bitcoind/templates/configmap.yaml), and custom values are read from dict `bitcoindCustomConfig`, which is defined near the bottom of values.yaml
      - Next time I would temporarily increase the following values, which are undefined in the chart:
        - DB cache: `dbcache=4096` (default is 450 MiB)
        - Verification thread count: `par=2` (default is auto, so 1 less than total CPU cores)
      - For details on other parameters, check out Lopp's [Bitcoin Core Config Generator](https://jlopp.github.io/bitcoin-core-config-generator/)
  - Q: How do I change the ingress hostname w/o re-deploying?
    - I accidentally left it as `bitcoind.test1.citadelic.org` from a previous run, when I was tracking down a DNS issue
    - My main concern is to avoid losing the chain data, although this will also be good to know for other situations in the future
    - It could be as simple as modifying `values.yaml` and running `helm upgrade`
  - Q: I see `rpcpassword` available as a var, but what is the proper way to set it?
    - A: Create a secret `bitcoind-rpcpassword` in the release namespace

## Galoy Charts Hardening

A quick review of the Galoy charts (and their git commit history) reveals a fair amount of hardening work has already been accomplished.

  - 
