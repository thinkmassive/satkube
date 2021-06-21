#!/bin/bash

. ./00-prerequisites.sh

# Return to current working dir on exit
CWD="$(pwd)"
function finish {
  cd $CWD
}
trap finish EXIT

INSTALL_NS=${INSTALL_NS:-false}
INSTALL_LND=${INSTALL_LND:-true}
NS=${NS:-satkube}
VALUES=${VALUES:-$CWD/helm_values/lnd/values.yaml}

echo INSTALL_LND=$INSTALL_LND

print_env
echo -e "\n(validate all values before proceeding!)\n"

echo "Install Helm charts?"
proceed_or_exit

if [ "$INSTALL_NS" == "true" ]; then
  echo "CREATING NAMESPACE"
  kubectl create namespace $NS
fi

if [ "$INSTALL_LND" == "true" ]; then
  cd charts/galoy/charts/lnd

  echo "Updating helm chart dependencies"
  helm dependency update

  echo -e "\nINSTALLING LND"
  helm install lnd . -f $VALUES -n $NS

  echo -n "Fetching lnd pod: "
  LND_POD=$(kubectl get pod -n $NS -l "app.kubernetes.io/name=lnd" -o jsonpath="{ .items[0].metadata.name }")
  echo $LND_POD
  echo "Forwarding port to lnd... "
  kubectl port-forward -n $NS $LND_POD 9735 &

  cd -
fi
