# SatKube

## Cloud Native Bitcoin Platform

This project is a proof-of-concept to determine the feasibility of running secure cloud-native Bitcoin infrastructure.

  - [Costs](#costs)
  - [Cluster provisioning](#cluster-provisioning)
  - [Bitnami Kubernetes Production Runtime](#bitnami-kubernetes-production-runtime) (BKPR)
  - [Bitnami KubeApps](#bitnami-kubeapps)

---

## ATTENTION

This project is under active development. The only guarantee is this branch will experience frequent commit reorgs until this notice is removed. Use at your own peril!

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

### Uninstall

```bash
./99-uninstall.sh
```

---

## Costs

AWS charges $0.10/hour per EKS cluster (for the control plane). The configuration below uses 3 m5.large instances, at a cost of $0.096/hour per instance.

This cluster will cost more than $9.31/day ($284/month) for compute resources. This does not include load balancers, data transfer, storage, and potentially other costs. Storage costs start around $50/mo for BKPR and $50/mo per node.

---

## Cluster Provisioning

Install common utilities:
  - [docker](https://docs.docker.com/engine/install/) (or other local container runtime, like [podman](https://podman.io/getting-started/installation.html))
  - [kubectl](https://kubernetes.io/docs/tasks/tools/)
  - [helm v3](https://helm.sh/docs/intro/install/)

### Amazon EKS

  - [Install awscli](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
  - [Install eksctl](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html)
  - Create AWS user:
    - Programmatic & Management Console access
    - IAM permissions:
      - AdministratorAccess
    - Tags:
      - Name: satkube

The following commands can be executed by running `01-provision.sh` in this repo.

First, populate environment variables:

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

#### EKS Clean up

To delete EVERYTHING created by eksctl when finished (note that additional AWS resources might be created by future steps, so those should either be deleted before this or cleaned up manually)

```bash
# This will DELETE EVERYTHING without prompting for confirmation
eksctl delete cluster --name $CLUSTER --region $REGION
```

---

## Bitnami Kubernetes Production Runtime

"The Bitnami Kubernetes Production Runtime ([BKPR](https://kubeprod.io/)) is a collection of services that make it easy to run production workloads in Kubernetes. The services are ready-to-run and pre-integrated with each other, so they work out of the box."

The following commands can be executed by running `02-bkpr-deploy.sh` in this repo.

### BKPR Cognito Setup

```bash
# Create Cognito user pool
aws cognito-idp create-user-pool --region $REGION --pool-name $CLUSTER --admin-create-user-config '{"AllowAdminCreateUserOnly": true}' --user-pool-tags "Project=$CLUSTER"

# Get the Cognito pool Id
export COGNITO_USER_POOL_ID=$(aws cognito-idp list-user-pools --region $REGION --max-results=1 | grep Id | awk -F'"' '{print $4}')

# Create Cognito user-pool domain (note this is not the domain name defined above, no dots allowed)
aws cognito-idp create-user-pool-domain --region $REGION --domain $CLUSTER --user-pool-id $COGNITO_USER_POOL_ID

# Create a Cognito user
aws cognito-idp admin-create-user \
  --region $REGION \
  --user-pool-id $COGNITO_USER_POOL_ID \
  --username $ADMIN_EMAIL \
  --user-attributes "Name=email,Value=$ADMIN_EMAIL"
```

You should receive an email with a temporary password to the address defined by `ADMIN_EMAIL`. If you get stuck resetting the password, refer to the [BKPR Quickstart](https://github.com/bitnami/kube-prod-runtime/blob/master/docs/quickstart-eks.md#create-a-user) for guidance.

At any time, if you are presented with an Amazon AWS authentication form, you can use this user account to authenticate against protected resources in BKPR.

### BKPR Deployment

First [install kubeprod](https://github.com/bitnami/kube-prod-runtime/blob/master/docs/install.md#install-kubeprod)

This guide was setup using **v1.8.0**

```bash
# Bootstrap your cluster with BKPR
kubeprod install eks \
  --email $ADMIN_EMAIL \
  --dns-zone $BKPR_DNS_ZONE \
  --user-pool-id $COGNITO_USER_POOL_ID

# Wait for all pods to enter Running state
watch kubectl get pods -n kubeprod

# Ensure your NS records match Route53
BKPR_DNS_ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "${BKPR_DNS_ZONE}" \
                                                         --max-items 1 \
                                                         --query 'HostedZones[0].Id' \
                                                         --output text)
aws route53 get-hosted-zone --id ${BKPR_DNS_ZONE_ID} --query DelegationSet.NameServers
```

### BKPR Web UIs

You can log into the BKPR web UIs using the Cognito account created earlier, `$ADMIN_EMAIL`

Where `<DNS_ZONE>` is the value set for `$DNS_ZONE`:

  - https://prometheus. &lt;DNS_ZONE&gt;
  - https://kibana. &lt;DNS_ZONE&gt;
  - https://grafana. &lt;DNS_ZONE&gt;

### BKPR Teardown and Cleanup

The following commands can be executed by running `99-uninstall.sh` in this repo.

```bash
# Uninstall BKPR
kubecfg delete kubeprod-manifest.jsonnet

# Wait for kubeprod namespace to be deleted
kubectl get -n kubeprod challenges.acme.cert-manager.io -oname| \
  xargs -rtI{} kubectl patch -n kubeprod {} \
    --type=json -p='[{"op": "remove", "path": "/metadata/finalizers"}]'
kubectl wait --for=delete ns/kubeprod --timeout=300s

# Delete hosted zone from Route53
BKPR_DNS_ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "${BKPR_DNS_ZONE}" \
                                                         --max-items 1 \
                                                         --query 'HostedZones[0].Id' \
                                                         --output text)
aws route53 list-resource-record-sets --hosted-zone-id ${BKPR_DNS_ZONE_ID} \
                                      --query '{ChangeBatch:{Changes:ResourceRecordSets[?Type != `NS` && Type != `SOA`].{Action:`DELETE`,ResourceRecordSet:@}}}' \
                                      --output json > changes

aws route53 change-resource-record-sets --cli-input-json file://changes \
                                        --hosted-zone-id ${BKPR_DNS_ZONE_ID} \
                                        --query 'ChangeInfo.Id' \
                                        --output text

aws route53 delete-hosted-zone --id ${BKPR_DNS_ZONE_ID} \
                               --query 'ChangeInfo.Id' \
                               --output text

# Delete user
ACCOUNT=$(aws sts get-caller-identity | jq -r .Account)
aws iam detach-user-policy --user-name "bkpr-${BKPR_DNS_ZONE}" --policy-arn "arn:aws:iam::${ACCOUNT}:policy/bkpr-${BKPR_DNS_ZONE}"
aws iam delete-policy --policy-arn "arn:aws:iam::${ACCOUNT}:policy/bkpr-${BKPR_DNS_ZONE}"
ACCESS_KEY_ID=$(jq -r .externalDns.aws_access_key_id kubeprod-autogen.json)
aws iam delete-access-key --user-name "bkpr-${BKPR_DNS_ZONE}" --access-key-id "${ACCESS_KEY_ID}"
aws iam delete-user --user-name "bkpr-${BKPR_DNS_ZONE}"

# Delete app client
USER_POOL=$(jq -r .oauthProxy.aws_user_pool_id kubeprod-autogen.json)
CLIENT_ID=$(jq -r .oauthProxy.client_id kubeprod-autogen.json)
aws cognito-idp delete-user-pool-client --user-pool-id "${USER_POOL}" --client-id "${CLIENT_ID}"

# Delete EKS cluster
eksctl delete cluster --name $CLUSTER
```

---

## Bitnami KubeApps

[KubeApps](https://kubeapps.com/) is a Kubernetes application dashboard from Bitnami.

### Kubeapps Installation

```bash
kubectl create namespace kubeapps
helm repo add bitnami https://charts.bitnami.com/bitnami

helm install kubeapps --namespace kubeapps \
  --set ingress.enabled=true \
  --set ingress.tls=true \
  --set ingress.certManager=true \
  --set ingress.hostname=kubeapps.$BKPR_DNS_ZONE \
  --set mongodb.metrics.enabled=true \
  bitnami/kubeapps
```

For a full list of parameters, refer to the [helm chart docs](https://hub.kubeapps.com/charts/bitnami/kubeapps)

When all pods are running, the web UI should be available at:
  - https://kubeapps.<DOMIAN>

### Kubeapps Authentication

The following creates a cluster-admin user for TEST PURPOSES ONLY

```bash
# Create an operator (cluster-admin) account
kubectl create serviceaccount kubeapps-operator
kubectl create clusterrolebinding kubeapps-operator \
  --clusterrole=cluster-admin \
  --serviceaccount=default:kubeapps-operator

# Get an access token to use w/webUI
kubectl get secret -o jsonpath='{.data.token}' \
    $(kubectl get serviceaccount kubeapps-operator -o jsonpath=' {.secrets[].name}') \
    | base64 --decode ; echo
```

Todo
  - [Install OIDC provider](https://github.com/kubeapps/kubeapps/blob/master/docs/user/using-an-OIDC-provider.md)
  - [Assign roles for apps](https://github.com/kubeapps/kubeapps/blob/master/docs/user/access-control.md#assigning-kubeapps-user-roles)

### Kubeapps Usage

You can install charts from the [Kubeapps Hub](https://hub.kubeapps.com/charts/bitnami)
