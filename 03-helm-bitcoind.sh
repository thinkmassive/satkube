#!/bin/bash

. ./00-prerequisites.sh

# Return to current working dir on exit
CWD="$(pwd)"
function finish {
  cd $CWD
}
trap finish EXIT

INSTALL_NS=${INSTALL_NS:-true}
INSTALL_BITCOIND=${INSTALL_BITCOIND:-true}
NS=${NS:-satkube}
VALUES=${VALUES:-$CWD/helm_values/bitcoind/values.yaml}

echo INSTALL_BITCOIND=$INSTALL_BITCOIND

print_env
echo -e "\n(validate all values before proceeding!)\n"

echo "Install Helm charts?"
proceed_or_exit

if [ "$INSTALL_NS" == "true" ]; then
  echo "CREATING NAMESPACE"
  kubectl create namespace $NS
fi

if [ "$INSTALL_BITCOIND" == "true" ]; then
  echo "INSTALLING BITCOIND"
  cd charts/galoy/charts/bitcoind
  helm install --debug bitcoind . -f $VALUES -n $NS

  # Follow instructions in Notes to test RPC
  echo -n "Fetching bitcoind pod: "
  BITCOIND_POD=$(kubectl get pod -n $NS -l "app.kubernetes.io/name=bitcoind" -o jsonpath="{ .items[0].metadata.name }")
  echo $BITCOIND_POD
  echo "Forwarding port to bitcoind... "
  kubectl port-forward -n $NS $BITCOIND_POD 8332 &

  CHAINTIPS_JSON="$(kubectl exec -n $NS -it bitcoind-0 -c bitcoind -- bitcoin-cli getchaintips)"
  CHAINTIP_ACTIVE=$(jq .[1].height <(echo $CHAINTIPS_JSON))
  CHAINTIP_HEADERS=$(jq .[0].height <(echo $CHAINTIPS_JSON))

  while [ "$CHAINTIP_ACTIVE" != "$CHAINTIP_HEADERS" ]; do
    echo "waiting for $CHAINTIP_ACTIVE to reach $CHAINTIP_HEADERS"
    sleep 60
    CHAINTIPS_JSON="$(kubectl exec -n $NS -it bitcoind-0 -c bitcoind -- bitcoin-cli getchaintips)"
    CHAINTIP_ACTIVE=$(jq .[1].height <(echo $CHAINTIPS_JSON))
    CHAINTIP_HEADERS=$(jq .[0].height <(echo $CHAINTIPS_JSON))
  done

  cd -
fi
