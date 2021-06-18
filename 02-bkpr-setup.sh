#!/bin/bash

. ./00-prerequisites.sh

print_env
echo -e "\n(validate all values before proceeding!)\n"

echo "Begin Cognito setup? (press 'y' to proceed, any other key to exit) "
read -n 1 -s -r keypress
[ "$keypress" != "y" ] && exit 0

# Cognito Setup

echo 'Creating Cognito user pool'
aws cognito-idp create-user-pool --region $REGION --pool-name $CLUSTER --admin-create-user-config '{"AllowAdminCreateUserOnly": true}' --user-pool-tags "Project=$CLUSTER"

echo -n 'Fetching the Cognito pool Id: '
export COGNITO_USER_POOL_ID=$(aws cognito-idp list-user-pools --region $REGION --max-results=1 | grep Id | awk -F'"' '{print $4}')
echo $COGNITO_USER_POOL_ID

echo 'Creating Cognito user-pool domain'
aws cognito-idp create-user-pool-domain --region $REGION --domain $CLUSTER --user-pool-id $COGNITO_USER_POOL_ID
# (note this is not the domain name defined above, no dots allowed)

echo 'Creating Cognito user'
aws cognito-idp admin-create-user \
  --region $REGION \
  --user-pool-id $COGNITO_USER_POOL_ID \
  --username $ADMIN_EMAIL \
  --user-attributes "Name=email,Value=$ADMIN_EMAIL"

# BKPR Deployment

echo "Deploy BKPR on the cluster? (press 'y' to proceed, any other key to exit) "
read -n 1 -s -r keypress
[ "$keypress" != "y" ] && exit 0

echo "Bootstrapping the cluster with BKPR"
kubeprod install eks \
  --email $ADMIN_EMAIL \
  --dns-zone $DNS_ZONE \
  --user-pool-id $COGNITO_USER_POOL_ID

echo -e "\nWait for all pods to enter 'Running' state (after they appear, press ctrl-c to continue)"
kubectl get pods -n kubeprod -w

echo -en "Fetching DNS zone id from Route53: "
DNS_ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "${DNS_ZONE}" \
                                                         --max-items 1 \
                                                         --query 'HostedZones[0].Id' \
                                                         --output text)
echo $DNS_ZONE_ID
echo "Ensure your NS records match this Route53 data:"
aws route53 get-hosted-zone --id $DNS_ZONE_ID --query DelegationSet.NameServers

echo -e "\nBPKR deployment complete\n----"
echo "Access these BKPR web UIs w/Cognito account: $ADMIN_EMAIL"
echo " - https://prometheus.$DNS_ZONE"
echo " - https://kibana.$DNS_ZONE"
echo " - https://grafana.$DNS_ZONE"

