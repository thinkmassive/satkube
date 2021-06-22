---
title: "Initial Assessment"
date: 2021-06-21T21:00:00Z
draft: false
summary: "An overview of the hardening efforts already completed, and some ideas for future security improvements."

---

Now that we finally have bitcoind, lnd, and BKPR deployments successfully running, it's time to evaluate the security posture of the cluster and figure out where our next efforts will be best spent.

## Chart Hardening

In this section I review the [GaloyMoney charts](https://github.com/GaloyMoney/charts/) for bitcoind and lnd, which are already secured fairly well.

### Security Context

[Security context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) defines privilege and access control settings for a Pod or Container.

Below are the pod and container security contexts defined in our values.yaml for the lnd chart (the bitcoind values are nearly identical):

```yaml
podSecurityContext:
  fsGroup: 2000

securityContext:
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: true
  runAsUser: 1000
  runAsNonRoot: true
```

Here we can see many security controls already in place. The containers run as an unprivileged user, which only has write access to the specific directories needed by it. The filesystem limitations contribute to enforcing immutability of containers at runtime.

Additionally, all capabilities are dropped, preventing use of any elevated privileges. Normal processes typically shouldn't need capabilities, but they are useful for hardening binaries that previously relied on the setuid bit.

Additional hardening might be accomplished by implementing SELinux, AppArmor, or seccomp. Figuring out the exact list of allowed calls is often a labor-intensive process, so this improvement can be deferred until more time-efficient hardening efforts are complete.

### RBAC

[Role-based access control](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) (RBAC) is enabled by default for these charts, as seen below:

```yaml
serviceAccount:
  # Specifies whether a service account should be created
  create: true
  # Annotations to add to the service account
  annotations: {}
  # The name of the service account to use.
  # If not set and create is true, a name is generated using the fullname template
  name: ""

rbac:
  create: true
```

This means the ServiceAccount, Role, and RoleBinding resources will be created at deploy time. These restrict which kubernetes API calls the corresponding deployment (bitciond or lnd) is authorized to make, limiting the blast radius in case the deployment is compromised.

### Network Policy

[NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/) is used to restrict a pod's ingress/egress to only the traffic allowed by the policy. Some malicious scenarios this could protect against include a compromised public-facing deployment trying to reach the LND API directly, or an exploit within the LND pod itself trying to fetch an additional payload from a public webserver.

The bitcoind chart has a NetworkPolicy defined, however the lnd chart does not, so that's one potentially simple improvement to be made.

## Supply Chain Hardening

The concept of a "software supply chain" is relatively new, even though people have been producing software for over half a century. Previously, software production seemed to have more in common with a fine craftsman working in a woodshop than with a factory primarily staffed by robots. Recently, thanks to DevOps principles and containerization, the supply chain analogy is now very relevant. Fortunately, the job of a platform engineer is vastly improved by concepts such as Software Bill of Materials (SBOM), container images (reproducible & immutable), build pipelines, and release batches (versioning).

We can restrict our in-house containers to a very limited set of base images. This provides the advantages of only needing to track a limited set of vulnerabilities and updates. It also simplifies the knowledge required to maintain a fleet of services, since processes will be the same everywhere. Some common base images with a minimal footprint include Alpine, Debian Slim, and RedHat Universal Base Image (UBI). This topic will be explored in detail in an upcoming post.

On the topic of vulnerability scanning, a container image provides a convenient level of abstraction for this to occur, since it's composed of filesystem layers that can easily be scanned at rest. Multiple open source tools are available, including Anchore's [grype](https://github.com/anchore/grype) and Aqua's [trivy](https://github.com/aquasecurity/trivy). When building our own images we should always verify the cryptographic signatures of binaries and code obtained from third-party sources.

Source code analysis is an area that's veering a bit far from the platform level, where this project is focused, but it's worth mentioning that more robust code results in microservices that are more secure and better performing. Static analysis tools and linters are available for every language, and adding test coverage for any bug that ever made it to production is mandatory. These types of tools and practices should be incorporated into every build pipeline.

## Cluster Hardening

### Kubernetes Version

Initially I used v1.18 because that was the latest version listed as compatible with BKPR v1.8.0 (latest stable version as of this post). Ideally we should upgrade to the latest stable Kubernetes release, v1.20. Additional investigation of BKPR compatibility and v1.9 release schedule is required to determine the feasibility of upgrading k8s.

### Audit Logging

[Auditing](https://kubernetes.io/docs/tasks/debug-application-cluster/audit/) is a kubernetes feature that allows us to define policies to record API requests received, started, and completed. Various backends are possible, including filesystem, [CloudWatch](https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html), and other external services reachable by webhook. The EFK service provided by BKPR is a likely candidate for this, but more investigation will be required to determine the optimal solution.

### Open Policy Agent

[Open Policy Agent](https://www.openpolicyagent.org/) (OPA) is a powerful tool for setting fine-grained policies on any nearly resource in the cluster. OPA [Gatekeeper](https://open-policy-agent.github.io/gatekeeper/) runs as an [admission controller](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/), which intercepts requests to the kubernetes API server so they can be mutated and/or validated. Polices are written in a language called [Rego](https://www.openpolicyagent.org/docs/latest/policy-language/), as assertions on the structured data coming in as API requests.

Some initial constraints that could be imposed by OPA:
  - Each deployment can only run container images with the specified digest
  - Container images may only come from an approved registry
  - Enforce deployment replica count to avoid resource exhaustion

### Runtime Security

Open source tools such as Sysdig's [Falco](https://sysdig.com/opensource/falco/) are available to continuously watch the cluster for malicious processes. This is one area where I don't have much prior experience, so a lot of learning is probably necessary before implementing anything that may impact our production workloads.
