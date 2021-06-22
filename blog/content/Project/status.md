---
title: "Project status"
date: 2021-06-17T21:52:37Z
weight: 30
draft: false
summary: "Current status, Roadmap, Releases, etc"

---

### Phase 0: Infrastructure Provisioning

To stay on target, initial scope is limited to the following items:
  - Gitlab.com
    - source code
    - build services
    - container registry
    - blog.satkube.com (this static site)
  - Amazon EKS cluster provisioned via CLI tools (eksctl, aws-cli)
  - Bitname Kubernetes Production Runtime
    - monitoring: prometheus, grafana
    - logging: elasticsearch, fluentd, kibana
    - ingress: nginx
  - website: citadelic.org

### Phase 1: Initial Nodes

  - single node instances for each of testnet & mainnet
    - bitcoind
    - lnd
  - Prometheus exporters
    - [bitcoin-prometheus-exporter](https://github.com/jvstein/bitcoin-prometheus-exporter)
    - [lndmon](https://github.com/lightninglabs/lndmon)
  - Applications
    - [mempool explorer](https://github.com/mempool/mempool)
    - [lndash](https://github.com/djmelik/lndash)

### Phase 2: Hardening

Hardening will follow topics covered by the [CNCF CKS](https://www.cncf.io/certification/cks/) exam [cirriculum](https://github.com/cncf/curriculum/blob/master/CKS_Curriculum_%20v1.20.pdf):

  - Cluster setup
  - System hardening
  - Monitoring & logging
  - Runtime security
  - Supply chain security
  - Microservice vulnerabilities

### Future Topics

  - LN payment gateway ([aperture](github.com/lightninglabs/aperture))
  - Membership system w/LN payments
  - Provide real member services
    - Bitcoin: nodes, indexers
    - Social: fediverse, chat
    - Infra: tor bridges, code & containers, build services, hosting
  - Self-host entire supply chain (code, build, containers)
  - Migrate from EKS to bare metal and/or other cloud providers
