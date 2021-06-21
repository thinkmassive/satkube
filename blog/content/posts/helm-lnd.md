---
title: "lnd helm chart"
date: 2021-06-21T12:00:00Z
draft: false
summary: "An overview of the 'lnd' helm chart from GaloyMoney"

---

Using [GaloyMoney/charts](https://github.com/GaloyMoney/charts/)

## Deployment Process

### lnd

First the LND pod is deployed, which starts with an init process to copy `lnd.conf` into the expected location, then starts the `lnd` process itself.

### lnd-wallet-init

### lnd-export-secrets

### cleanup-hook

This appears to not yet be fully working, based on the code being [commented out](https://github.com/GaloyMoney/charts/blob/main/charts/lnd/templates/cleanup-hook.yaml).

### Probes

One improvement could be implementing a [startup probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes) in addition to the liveness and readiness probes. This is mainly a quality of life improvement that prevents the other probes from interfering with the startup process and cluttering logs, although if the container actually starts much faster than InitialDelaySeconds, the faster startup time could be a performance improvement.
