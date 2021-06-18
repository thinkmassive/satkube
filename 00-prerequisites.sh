#!/bin/bash

#[ $(sudo whoami) != 'root' ] && { echo 'This script must be run as root.' ; exit 1 ; }

proceed_or_exit () {
  echo " (press 'y' to proceed, any other key to exit) "
  read -n 1 -s -r keypress
  [ "$keypress" != "y" ] && exit 0
}

check_for_binaries () {
  echo -e '\nChecking for binaries...'
  DOCKER_STATUS=$(which docker > /dev/null ; echo $?)
  KUBECTL_STATUS=$(which kubectl > /dev/null ; echo $?)
  HELM_STATUS=$(which helm > /dev/null ; echo $?)
  AWSCLI_STATUS=$(which aws > /dev/null ; echo $?)
  EKSCTL_STATUS=$(which eksctl > /dev/null ; echo $?)
  KUBEPROD_STATUS=$(which kubeprod > /dev/null ; echo $?)

  [ $DOCKER_STATUS != 0 ] && echo "Missing 'docker', refer to https://docs.docker.com/engine/install" || echo "Found 'docker'"
  [ $KUBECTL_STATUS != 0 ] && echo "Missing 'kubectl', refer to https://kubernetes.io/docs/tasks/tools" || echo "Found 'kubectl'"
  [ $HELM_STATUS != 0 ] && echo "Missing 'helm', refer to https://helm.sh/docs/intro/install" || echo "Found 'helm'"
  [ $AWSCLI_STATUS != 0 ] && echo "Missing 'aws', refer to https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html" || echo "Found 'aws'"
  [ $EKSCTL_STATUS != 0 ] && echo "Missing 'eksctl', refer to https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html" || echo "Found 'eksctl'"
  [ $KUBEPROD_STATUS != 0 ] && echo "Missing 'kubeprod', refer to https://github.com/bitnami/kube-prod-runtime/blob/master/docs/install.md#install-kubeprod" || echo "Found 'kubeprod'"
}

set_env () {
  echo -en '\nSetting environment variables... '
  
  export CLUSTER=${CLUSTER:-satkube}
  export REGION=${REGION:-us-east-1}
  export K8S_VERSION=${K8S_VERSION:-1.18}
  export NODE_COUNT=${NODE_COUNT:-3}
  export DNS_ZONE=${DNS_ZONE:-citadelic.org}
  export ADMIN_EMAIL=${ADMIN_EMAIL:-me@example.com}
  echo done
}

print_env () {
  echo "CLUSTER: $CLUSTER"
  echo "REGION: $REGION"
  echo "K8S_VERSION: $K8S_VERSION"
  echo "NODE_COUNT: $NODE_COUNT"
  echo "DNS_ZONE: $DNS_ZONE"
  echo "ADMIN_EMAIL: $ADMIN_EMAIL"
}

check_for_binaries
set_env
