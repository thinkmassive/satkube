# SatKube

## Cloud Native Bitcoin Platform

This project is a proof-of-concept to determine the feasibility of running secure cloud-native Bitcoin infrastructure.

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

```bash
# Populate common environment variables
export CLUSTER=satkube
export REGION=us-east-1

# Populate EKS environment variables
export BKPR_DNS_ZONE=satkube.com
export AWS_EKS_USER=me@example.com
export K8S_VERSION=1.20
#export AWS_EKS_CLUSTER=$CLUSTER

# Provision EKS cluster on Fargate (adjust params as desired)
eksctl create cluster \
  --name $CLUSTER \
  --region $REGION \
  --zones ${REGION}a,${REGION}b \
  --version $K8S_VERSION \
  --fargate

# Ensure cluster creation doesn't fail early, possibly due to insufficient
#  resources in the specificed AZs. Adjust params if needed, run again, then
#  wait for cluster provisioning to complete (about 15 min).

# Verify nodes & workload
kubectl get nodes
kubectl get pods -A

# If you need to restore kubeconfig:
aws eks update-kubeconfig --name=$CLUSTER

```

#### Install the AWS Load Balancer Controller

Follow the [User Guide](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html) to install the AWS Load Balancer Controller. This controller manages ALBs (for `Ingress`) and NLBs (for `LoadBalancer`).

This project was formerly named the AWS ALB Ingress Controller. It was renamed and continues to be improved. Code is on [GitHub](https://github.com/kubernetes-sigs/aws-load-balancer-controller).

```bash
# Populate environment variables & display for verification
export AWS_ACCT_ID=$(aws iam get-user | grep -i 'arn:aws:iam' | awk -F':' '{print $6}')
export VPC_ID=$(eksctl get cluster --name satkube -o yaml | grep VpcId | awk '{print $2}')
echo "AWS_ACCT_ID: $AWS_ACCT_ID  VPC_ID: $VPC_ID"

# Enable IAM OIDC provider
eksctl utils associate-iam-oidc-provider --region=$REGION --cluster=$CLUSTER --approve

# Download & apply IAM policy
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.2.0/docs/install/iam_policy.json
aws iam create-policy \
   --policy-name AWSLoadBalancerControllerIAMPolicy \
   --policy-document file://iam_policy.json

# Create IAM service account for ALB
eksctl create iamserviceaccount \
  --cluster=$CLUSTER \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::$AWS_ACCT_ID:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve

# Install TargetGroupBinding CRD
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

# Add eks-charts Helm repo & update local charts
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install AWS Load Balancer Controller from helm chart
helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
  --set clusterName=$CLUSTER \
  --set region=$REGION \
  --set vpcId=$VPC_ID \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  -n kube-system

# Verify controller installation (may take a few minutes, keep watching)
kubectl get deployment -n kube-system aws-load-balancer-controller
```

##### Verify the Load Balancer Controller (optional)

You may verify the LBC installation (and general cluster operation) by
deploying the `game-2048` sample app

```bash
kubectl create namespace game-2048
eksctl create fargateprofile --cluster $CLUSTER --region $REGION --name my-alb-sample-app --namespace game-2048
curl -o 2048_full.yaml https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.1.3/docs/examples/2048/2048_full.yaml
kubectl apply -f 2048_full.yaml

# when all resources are ready, visit ingress ADDRESS in a web browser
kubectl get all -n game-2048
kubectl get ingress/ingress-2048 -n game-2048

# clean up by deleting resources when finished
kubectl delete -f 2048_full.yaml
eksctl delete fargateprofile --cluster $CLUSTER --region $REGION --name my-alb-sample-app --namespace game-2048

# ensure the aws-load-balancer resources remain, and all game-2048 resources are gone
kubectl get all -A
```

#### To delete EVERYTHING when finished

```bash
# This will DELETE EVERYTHING without prompting for confirmation
eksctl delete cluster --name $CLUSTER --region $REGION
```

---

## Bitnami Kubernetes Production Runtime

"The Bitnami Kubernetes Production Runtime ([BKPR](https://kubeprod.io/)) is a collection of services that make it easy to run production workloads in Kubernetes. The services are ready-to-run and pre-integrated with each other, so they work out of the box."

### BKPR Cognito Setup

```bash
# Create Cognito user pool
aws cognito-idp create-user-pool --pool-name $CLUSTER --admin-create-user-config '{"AllowAdminCreateUserOnly": true}' --user-pool-tags 'Project=satkube'

# Get the Cognito pool Id
export AWS_COGNITO_USER_POOL_ID=$(aws cognito-idp list-user-pools --max-results=1 | grep Id | awk -F'"' '{print $4}')

# Create Cognito user-pool domain (note this is not the domain name defined above, no dots allowed)
aws cognito-idp create-user-pool-domain --domain $CLUSTER --user-pool-id $AWS_COGNITO_USER_POOL_ID

# Create a Cognito user
aws cognito-idp admin-create-user \
  --user-pool-id $AWS_COGNITO_USER_POOL_ID \
  --username $AWS_EKS_USER \
  --user-attributes Name=email,Value=$AWS_EKS_USER
```

You should receive an email with a temporary password to the address defined by `AWS_EKS_USER`. If you get stuck resetting the password, refer to the [BKPR Quickstart](https://github.com/bitnami/kube-prod-runtime/blob/master/docs/quickstart-eks.md#create-a-user) for guidance.

At any time, if you are presented with an Amazon AWS authentication form, you can use this user account to authenticate against protected resources in BKPR.

### BKPR Fargate Profile Setup

```bash
eksctl create fargateprofile --cluster $CLUSTER --name kubeprod --namespace kubeprod
```

### BKPR Deployment

First [install kubeprod](https://github.com/bitnami/kube-prod-runtime/blob/master/docs/install.md#install-kubeprod)

This guide was setup using **v1.8.0**

```bash
# Bootstrap your cluster with BKPR
kubeprod install eks \
  --email $AWS_EKS_USER \
  --dns-zone $BKPR_DNS_ZONE \
  --user-pool-id $AWS_COGNITO_USER_POOL_ID

# Wait for all pods to enter Running state
watch kubectl get pods -n kubeprod
```
