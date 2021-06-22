---
title: "Lightning Network Daemon"
date: 2021-06-21T12:00:00Z
draft: false
weight: 20
summary: "An overview of the 'lnd' helm chart from GaloyMoney"

---

Using [GaloyMoney/charts](https://github.com/GaloyMoney/charts/)

## Installation

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

Make sure to **fetch tls.cert, admin.macaroon, and the wallet seed** using instructions from the NOTES output!

---

## Config
  - `lndGeneralConfig` is used to populate lnd.conf in ConfigMap
  - `configmap.customValues` is available for customization

### Secrets
  - `network`
    - set in values.yaml, defines mainnet/testnet/regtest/simnet
    - shared by bitcoind & lnd (global)
  - `lnd-pass`
    - populated by helm ([lnd-pass-secret](https://github.com/GaloyMoney/charts/blob/main/charts/lnd/templates/lnd-pass-secret.yaml)) if it doesn't [already exist](https://github.com/GaloyMoney/charts/blob/lnd-1.2.6/charts/lnd/templates/_helpers.tpl#L64-L78)
    - used as env var `LND_PASS` to generate wallet (wallet-init-hook) and to unlock wallet (init.sh)
  - `lnd-pubkey`
    - populated by export-secrets-hook
    - used for display to operator (for use in client apps)
  - `lnd-credentials`
    - populated by export-secrets-hook
    - used for display to operator (for use in client apps)

### Persistence
  - Enabled by default, using the default provisioner (gp2 on AWS) to create a 10GiB volume
    - `/data/.lnd/`
  - Resource policy is `keep`, which means the volume will not be deleted during uninstall
  - To use an existing PVC: `persistence.existingClaim`

### Ingress
  - Disabled by default
  - Enable if external users (outside the cluster) will need access to the LND API

### RBAC
  - Enabled by default (disable to manage outside of helm)
  - `ServiceAccount`: `lnd`
  - `Role`: grants permission to get/list/watch and exec into pods
  - `RoleBinding`: binds the Role to the ServiceAccount

### Resources
  - Commented out by default, but recommend defining these to avoid pod termination
  - Depends on host resources, good starting point:
    - request: 100m CPU, 128Mi mem
    - limit: 1000m CPU, 1024Mi mem

### Probes
  - Startup
  - Liveness
  - Readiness

---

## Deploy Process

### lnd

First the LND pod is deployed, which starts with an init container to copy `lnd.conf` into the expected location. Next the `lnd` container runs the script `/root/init.sh`, which launches `lnd` and enters a loop until the `lncli unlock` command succeeds.

### hook: lnd-wallet-init

Post-install hook that uses an [expect](https://linux.die.net/man/1/expect) script, [walletInit.exp](https://github.com/GaloyMoney/charts/blob/main/charts/lnd/templates/wallet-init-configmap.yaml), to enter the LND password and generate a new wallet. The seed is stored unencrypted.

### hook: lnd-export-secrets

Post-install and post-upgrade hook that runs after lnd-wallet-init. Runs [exportSecrets.sh](https://github.com/GaloyMoney/charts/blob/main/charts/lnd/templates/export-secrets-configmap.yaml) to create these Secrets:
  - pubkey (fetched from `lncli getinfo`)
  - credentials (tls.cert & admin.macaroon, base64 encoded)

### hook: cleanup-hook

Pre-delete [hook](https://github.com/GaloyMoney/charts/blob/main/charts/lnd/templates/cleanup-hook.yaml) that does not yet work as intended. It sounds like there's a race condition interfering with proper deletion of the `lnd-credentials` secret. **This is sensitive data that should be manually cleaned up until this hook is working.**

### Probes

One improvement could be implementing a [startup probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes) in addition to the liveness and readiness probes. This is mainly a quality of life improvement that prevents the other probes from interfering with the startup process and cluttering logs, although if the container actually starts much faster than InitialDelaySeconds, the faster startup time could be a performance improvement.
