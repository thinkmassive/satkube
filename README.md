# SatKube

## Cloud Native Bitcoin Platform

Refer to the [SatKube handbook](https://satkube.com) for detailed documentation.

---

## Quickstart

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
./02-bkpr-deploy.sh

# Install bitcoind & lnd from helm charts
./03-helm-bitcoind.sh
./04-helm-lnd.sh
```

## Uninstall

```bash
./99-uninstall.sh
```
