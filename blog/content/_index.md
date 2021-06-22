## Cloud-native Bitcoin

Welcome to the home of Satoshi's Kubernetes stack!

SatKube is a reference implementation of a Bitcoin and Lightning application platform that runs on Kubernetes.

The following basic components are installed, currently undergoing configuration:
  - Bitcoin Core (bitcoind)
  - Lightning Network Daemon (lnd)
  - Logging (Elasticsearch, Fluentd, Kibana)
  - Metrics (Prometheus, Grafana)
  - Ingress (nginx-ingress, Let's Encrypt)
  - Authn (OAuth2-Proxy)

So far it's been tested on Amazon EKS. When the platform is operational and hardening is complete, we will evaluate other providers and bare metal, then determine an appropriate IaC solution.

Feel free to explore the docs (menu on the left), and the source code at [GitLab](https://gitlab.com/thinkmassive/satkube) (primary) or [GitHub](https://github.com/thinkmassive/satkube) (mirror)
