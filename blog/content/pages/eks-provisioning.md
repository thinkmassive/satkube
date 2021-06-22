---
title: "EKS Cluster Provisioning"
date: 2021-06-18T20:29:31Z
draft: false
summary: "Provisioning an Amazon EKS cluster to host our SatKube installation"

---

Install common utilities:

  - docker (or other local container runtime, like podman)
  - kubectl
  - helm v3

Amazon EKS

  - Install awscli
  - Install eksctl
  - Create AWS user:
    -  Programmatic & Management Console access
    - IAM permissions:
      - AdministratorAccess
    - Tags:
      - Name: satkube

```bash
# Populate common environment variables
export CLUSTER=satkube
export REGION=us-east-2

# Populate EKS environment variables
export K8S_VERSION=1.18
export BKPR_DNS_ZONE=satkube.com
export ADMIN_EMAIL=me@example.com

# Review variables before applying changes
echo -e "CLUSTER: $CLUSTER\nREGION: $REGION\nK8S_VERSION: $K8S_VERSION\nBKPR_DNS_ZONE: $BKPR_DNS_ZONE\nADMIN_EMAIL: $ADMIN_EMAIL"

# Provision EKS cluster (adjust params as desired)
eksctl create cluster \
  --name $CLUSTER \
  --region $REGION \
  --version $K8S_VERSION \
  --nodes=3 \
  --ssh-access

# Wait for cluster provisioning to complete (often ~15 min)

# Verify nodes & workload
kubectl get nodes
kubectl get pods -A

# If you need to restore kubeconfig:
aws eks update-kubeconfig --name=$CLUSTER
```

Note that EKS operations may take a while to complete, sometimes long after the command completes for async tasks.

