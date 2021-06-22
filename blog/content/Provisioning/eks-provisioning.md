---
title: "EKS Cluster Provisioning"
date: 2021-06-18T20:29:31Z
draft: false
summary: "Provisioning an Amazon EKS cluster to host our SatKube installation"

---

## Prerequisites

Install common utilities:
  - [docker](https://docs.docker.com/engine/install/) (or other local container runtime, like [podman](https://podman.io/getting-started/installation.html))
  - [kubectl](https://kubernetes.io/docs/tasks/tools/)
  - [helm v3](https://helm.sh/docs/intro/install/)

Install AWS utilities:

  - Install awscli
  - Install eksctl

Set up AWS user &amp; IAM:

  - Create AWS user:
    -  Programmatic & Management Console access
    - IAM permissions:
      - AdministratorAccess
    - Tags:
      - Name: satkube

## eksctl

The following commands can be executed by running `01-eks-provisioning.sh`

### Configuration

```bash
export CLUSTER=satkube
export REGION=us-east-2
export K8S_VERSION=1.18
export NODE_COUNT=3
export DNS_ZONE=citadelic.org
export ADMIN_EMAIL=me@example.com
```

Review all variables, then provision the EKS cluster:

```bash
# Provision EKS cluster (adjust params as desired)
eksctl create cluster \
  --name $CLUSTER \
  --region $REGION \
  --version $K8S_VERSION \
  --nodes=3 \
  --ssh-access
```

Wait for cluster provisioning to complete, which often takes about 15 minutes. Then verify the nodes are ready and pods are running:

```bash
kubectl get nodes
kubectl get pods -A
```

Your kubeconfig should automatically be updated, but in case you need to manually restore it:

```bash
aws eks update-kubeconfig --name=$CLUSTER --region=$REGION
```

## Clean up

To delete EVERYTHING created by eksctl when finished (note that additional AWS resources might be created by future steps, so those should either be deleted before this or cleaned up manually)

```bash
# This will DELETE EVERYTHING without prompting for confirmation
eksctl delete cluster --name $CLUSTER --region $REGION
```
