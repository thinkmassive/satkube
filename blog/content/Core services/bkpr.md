---
title: "BKPR/kubeprod"
date: 2021-06-19T16:31:49Z
draft: false
weight: 10
summary: "BKPR (aka kubeprod) is a collection of ready-to-run and pre-integrated services for operating a Kubernetes production environment. It covers logging, metrics, ingress, and authentication."

---

The Bitnami Kubernetes Production Runtime ([BKPR](https://kubeprod.io/)) is a collection of ready-to-run and pre-integrated services for operating a Kubernetes production environment:
  - Logging: Elasticsearch, Flutentd, Kibana
  - Metrics: Prometheus, Grafana
  - Ingress: nginx-ingress, Let's Encrypt
  - Authentication: OAuth2 Proxy

Prometheus and EFK are the most common FOSS solutions for metrics and logging, so there are many options from fully hosted to roll-your-own IaC. I first learned of BKPR from a [comment in the lndmon repo](https://github.com/lightninglabs/lndmon/pull/60#discussion_r545212531). Bitnami is trusted in the cloud-native space, and if Lightning Labs uses kubeprod that's a good endorsement for me to try it as a core component of my own Bitcoin platform.

### Helpful References

  - [Install kubeprod](https://github.com/bitnami/kube-prod-runtime/blob/master/docs/install.md#install-kubeprod) (local installer binary)
  - [App Dev Guide](https://github.com/bitnami/kube-prod-runtime/blob/master/docs/application-developers-reference-guide.md)

### Deployment

This guide was setup using **v1.8.0** on Amazon EKS.

The following commands can be executed by running `03-bkpr-setup.sh`

#### AWS Cognito Setup

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

#### BKPR Deployment

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

### Web UIs

You can log into the BKPR web UIs using the Cognito account created earlier, `$ADMIN_EMAIL`

Where `<DNS_ZONE>` is the value set for `$DNS_ZONE`:

  - https://prometheus. &lt;DNS_ZONE&gt;
  - https://kibana. &lt;DNS_ZONE&gt;
  - https://grafana. &lt;DNS_ZONE&gt;

```

Pro tip: call it "beekeeper" to remember the spelling

### Teardown and Cleanup

The following commands can be executed by running `99-uninstall.sh`

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
