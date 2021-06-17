---
title: "Intro to SatKube"
date: 2021-06-17T21:52:37Z
draft: false
summary: "Motivation, goals, and specification for the initial SatKube and citadelic projects."

---

# Motivation

This project, along with the target application (see below), have been marinating in my brain for a while. Now, in June 2021, they finally reached critical mass to launch as a serious open source project.

During the past five years I've encountered cryptocurrency environments that range from traditional infra concepts running on cloud resources, to the latest cloud-native everything-on-kubernetes. As much as I enjoy working on new tech, the most secure environments tend to be on the legacy end of the spectrum (though certainly not all legacy environments are secure!). Building a Bitcoin application stack happens to be a great case study for platform security.

This project (SatKube) aims to accomplish for enterprise-grade Bitcoin platforms, what the multitude of Raspberry Pi node distros accomplished for individual Bitcoin infrastructure. The target application (citadelic.org) is my attempt to demonstrate cloud-native security concepts, and eventually to provide a useful service to the community.

# Goals

In the near term, my goal is to build a secure platform for building and operating Bitcoin applications. I will take a learn-in-public approach, starting from an Amazon EKS Quickstart environment, and document my progression as the project evolves. Eventually I hope to migrate to bare metal, but I chose EKS to start because it provides a decent balance of convenience and stability, especially for a one-person project.

The target application is a new project, the Citadel Infrastructure Cooperative, which will provide Bitcoin-related services (APIs & data) to its members and the public. I would like it to support both membership-based accounts and pay-as-you-go API services. Initially its target userbase is the moderate to advanced technical user who prefers to share technical duties and operational costs. As the project becomes self-sustaining, the goal is to provide services for non-technical end users, so they can reap the benefits of the new financial system instead of losing them to highly centralized services.

# Specifications

## Phase 0: Infrastructure Provisioning

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

## Phase 1: Initial Nodes

  - single node instances for each of testnet & mainnet
    - bitcoind
    - lnd
  - Prometheus exporters
    - [bitcoin-prometheus-exporter](https://github.com/jvstein/bitcoin-prometheus-exporter)
    - [lndmon](https://github.com/lightninglabs/lndmon)
  - Applications
    - [mempool explorer](https://github.com/mempool/mempool)
    - [lndash](https://github.com/djmelik/lndash)

## Phase 2: Hardening

Hardening will follow topics covered by the [CNCF CKS](https://www.cncf.io/certification/cks/) exam [cirriculum](https://github.com/cncf/curriculum/blob/master/CKS_Curriculum_%20v1.20.pdf):

  - Cluster setup
  - System hardening
  - Monitoring & logging
  - Runtime security
  - Supply chain security
  - Microservice vulnerabilities

## Future Topics

  - LN payment gateway ([aperture](github.com/lightninglabs/aperture))
  - Membership system w/LN payments
  - Provide real member services
    - Bitcoin: nodes, indexers
    - Social: fediverse, chat
    - Infra: tor bridges, code & containers, build services, hosting
  - Self-host entire supply chain (code, build, containers)
  - Migrate from EKS to bare metal and/or other cloud providers

# Feedback

Please get in touch! I want to cover topics the community finds useful or interesting. Questions, concerns, suggestions... all are helpful and welcome.

If you like this project, consider sharing it with a person or group who also may find it interesting.

I can be reached on [Mastadon](https://ctdl.co/thinkmassive), [Twitter](https://twitter.com/thinkmassive), Matrix (thinkmassive), or by email.
