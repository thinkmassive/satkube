---
title: "BKPR/kubeprod"
date: 2021-06-19T16:31:49Z
draft: false
summary: "BKPR (aka kubeprod) is a collection of ready-to-run and pre-integrated servicesj for operating a Kubernetes production environment. It covers logging, metrics, ingress, and authentication."

---

Bitnami Kubernetes Production Runtime, aka BKPR or kubeprod, is a collection of ready-to-run and pre-integrated servicesj for operating a Kubernetes production environment:
  - Logging: Elasticsearch, Flutentd, Kibana
  - Metrics: Prometheus, Grafana
  - Ingress: nginx-ingress, Let's Encrypt
  - Authentication: OAuth2 Proxy

Prometheus and EFK are the most common FOSS solutions for metrics and logging, so there are many options from fully hosted to roll-your-own IaC. I first learned of BKPR from a [comment in the lndmon repo](https://github.com/lightninglabs/lndmon/pull/60#discussion_r545212531). Bitnami is trusted in the cloud-native space, and if Lightning Labs uses kubeprod that's a good endorsement for me to try it as a core component of my own Bitcoin platform.

Helpful References
  - [Install kubeprod](https://github.com/bitnami/kube-prod-runtime/blob/master/docs/install.md#install-kubeprod)
  - [App Dev Guide](https://github.com/bitnami/kube-prod-runtime/blob/master/docs/application-developers-reference-guide.md)

This guide was setup using **v1.8.0**

```bash
./03-bkpr.sh
```

Pro tip: call it "beekeeper" to remember the spelling
