#!/bin/bash
. ./00-prerequisites.sh

UNINSTALL_BKPR=${UNINSTALL_BKPR:-true}
UNINSTALL_ROUTE53=${UNINSTALL_ROUTE53:-true}
UNINSTALL_IAM=${UNINSTALL_IAM:-true}
UNINSTALL_COGNITO=${UNINSTALL_COGNITO:-true}
UNINSTALL_EKS=${UNINSTALL_EKS:-true}

echo UNINSTALL_BKPR=$UNINSTALL_BKPR
echo UNINSTALL_ROUTE53=$UNINSTALL_ROUTE53
echo UNINSTALL_IAM=$UNINSTALL_IAM
echo UNINSTALL_COGNITO=$UNINSTALL_COGNITO
echo UNINSTALL_EKS=$UNINSTALL_EKS

print_env
echo -en "\nPROCEED WITH UNINSTALL?"
proceed_or_exit

if [ $UNINSTALL_BKPR = true ]; then
  echo -n "Uninstall BKPR?"
  proceed_or_exit
  echo "uninstalling kubeprod..."
  kubecfg delete kubeprod-manifest.jsonnet
  
  # Specific finalizers cleanup, to avoid kubeprod ns lingering
  # - cert-manager challenges if TLS certs have not been issued
  echo "Cleaning up finalizers to allow namespace to terminate"
  kubectl get -n kubeprod challenges.acme.cert-manager.io -oname| \
    xargs -rtI{} kubectl patch -n kubeprod {} \
      --type=json -p='[{"op": "remove", "path": "/metadata/finalizers"}]'
  
  echo "Waiting for namespace termination to complete"
  kubectl wait --for=delete ns/kubeprod --timeout=300s
fi
  
if [ $UNINSTALL_ROUTE53 = true ]; then
  echo -e "\nROUTE53 CLEANUP"
  echo -n "Deleting Route53 hosted zone id: "
  DNS_ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name="$DNS_ZONE" --max-items=1 --query='HostedZones[0].Id' --output=text)
  echo $DNS_ZONE_ID
  aws route53 list-resource-record-sets --hosted-zone-id=$DNS_ZONE_ID --query='{ChangeBatch:{Changes:ResourceRecordSets[?Type != `NS` && Type != `SOA`].{Action:`DELETE`,ResourceRecordSet:@}}}' --output=json > changes
  aws route53 change-resource-record-sets --cli-input-json file://changes --hosted-zone-id=$DNS_ZONE_ID --query='ChangeInfo.Id' --output=text
  aws route53 delete-hosted-zone --id=$DNS_ZONE_ID --query='ChangeInfo.Id' --output=text
fi
  
if [ $UNINSTALL_IAM = true ]; then
  echo "IAM CLEANUP"
  ACCOUNT=$(aws sts get-caller-identity | jq -r .Account)
  echo "ACCOUNT=$ACCOUNT"
  aws iam detach-user-policy --region=$REGION --user-name="bkpr-$DNS_ZONE" --policy-arn="arn:aws:iam::$ACCOUNT:policy/bkpr-$DNS_ZONE"
  aws iam delete-policy --region=$REGION --policy-arn="arn:aws:iam::$ACCOUNT:policy/bkpr-$DNS_ZONE"
  ACCESS_KEY_ID=$(jq -r .externalDns.aws_access_key_id kubeprod-autogen.json)
  echo "ACCESS_KEY_ID=$ACCESS_KEY_ID"
  aws iam delete-access-key --region=$REGION --user-name="bkpr-$DNS_ZONE" --access-key-id "$ACCESS_KEY_ID"
  sleep 5
  aws iam delete-user --region=$REGION --user-name="bkpr-$DNS_ZONE"
fi

if [ $UNINSTALL_COGNITO = true ]; then
  echo -e "\nCOGNITO CLEANUP"
  if [ -f kubeprod-autogen.json ]; then
    [ ! $USER_POOL ] && USER_POOL=$(jq -r .oauthProxy.aws_user_pool_id kubeprod-autogen.json)
    [ ! $CLIENT_ID ] && CLIENT_ID=$(jq -r .oauthProxy.client_id kubeprod-autogen.json)

    echo "Deleting BPKR app client"
    aws cognito-idp delete-user-pool-client --region=$REGION --user-pool-id=$USER_POOL --client-id=$CLIENT_ID
  
    echo "Deleting BPKR user pool domain"
    aws cognito-idp delete-user-pool-domain --region=$REGION --domain=$CLUSTER --user-pool-id=$USER_POOL
  
    echo "Deleting BPKR user pool"
    aws cognito-idp delete-user-pool --region=$REGION --user-pool-id=$USER_POOL
  else
    echo "ATTENTION: you will need to manually `aws cognito-idp delete-user-pool`"
  fi
fi

echo -e "\nUninstall Complete\n"
echo "Remaining kubernetes resources:"
kubectl get all -A
  
echo -e "\n\n!!!! ATTENTION !!!!\nThe following files remain:\n"
ls -l kubeprod-*.json*
echo -e "\n!!!!!!!!!!!!!!!!!!!\n"

if [ $UNINSTALL_EKS = true ]; then  
  echo -n "Delete EKS cluster?"
  proceed_or_exit
  echo "Deleting EKS cluster"
  eksctl delete cluster --name=$CLUSTER
fi

