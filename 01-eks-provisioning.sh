#!/bin/bash
. ./00-prerequisites.sh

print_env
echo -e "\n(validate all values before proceeding!)\n"

echo "Provision the EKS cluster?"
proceed_or_exit

# Provision EKS cluster on (adjust params as desired)
eksctl create cluster \
  --name $CLUSTER \
  --region $REGION \
  --version $K8S_VERSION \
  --nodes=$NODE_COUNT \
  --ssh-access

[ $? != '0' ] && { echo -e '\neksctl terminated abnormally, please investigate before proceeding!'; exit 1; }

echo -e "\nChecking nodes (all should be 'Ready')"
kubectl get nodes

echo -e "\nChecking pods (all should be 'Running')"
kubectl get pods -A
