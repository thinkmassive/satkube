---
title: "Quickstart"
date: 2021-06-17T21:52:37Z
weight: 20
draft: false
summary: "Essential commands for bringing up a SatKube instance."

---

```bash
# clone this repo, including submodules, and enter the project root
git clone --recurse-submodules https://gitlab.com:thinkmassive/satkube
cd satkube

# if you cloned w/o submodules, fetch them now:
git submodule init
git submodule update

# Verify software dependencies are met (resolve before proceeding)
./00-prerequisites.sh

# Provision an Amazon EKS cluster
./01-eks-provision.sh

# Deploy Bitname Kubernetes Production Runtime
./02-bkpr-setup.sh

# Install bitcoind & lnd from helm charts
./03-helm-bitcoind.sh
./04-helm-lnd.sh
```

## Uninstall

```bash
./99-uninstall.sh
```
