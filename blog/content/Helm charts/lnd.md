---
title: "Lightning Network Daemon"
date: 2021-06-21T12:00:00Z
draft: false
weight: 20
summary: "An overview of the 'lnd' helm chart from GaloyMoney"

---

Using [GaloyMoney/charts](https://github.com/GaloyMoney/charts/)

## lnd installation

The following commands can be executed by running `04-helm-lnd.sh`

```bash
# Define namespace
NS=satkube

# Define values.yaml file (review and adjust as desired before proceeding)
VALUES=$(pwd)/helm_values/lnd/values.yaml

# Change to chart dir
cd charts/galoy/charts/lnd

# Install via helm
helm install lnd . -f $VALUES -n $NS
```

### lnd

First the LND pod is deployed, which starts with an init container to copy `lnd.conf` into the expected location. Next the `lnd` container starts the `lnd` daemon.

### lnd-wallet-init

Next, a wallet init process waits for LND to become available, then it creates a new wallet.

### lnd-export-secrets

### cleanup-hook

The [cleanup-hook](https://github.com/GaloyMoney/charts/blob/main/charts/lnd/templates/cleanup-hook.yaml) is not yet working as intended. It sounds like there's a race condition interfering with proper deletion of the macaroon and tls configmaps. **This is sensitive data that should be manually cleand up until this hook is working.**

### Probes

One improvement could be implementing a [startup probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes) in addition to the liveness and readiness probes. This is mainly a quality of life improvement that prevents the other probes from interfering with the startup process and cluttering logs, although if the container actually starts much faster than InitialDelaySeconds, the faster startup time could be a performance improvement.
