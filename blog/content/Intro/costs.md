---
title: "Costs"
date: 2021-06-21T01:23:45Z
draft: false
weight: 30
---

AWS charges $0.10/hour per EKS cluster (for the control plane). The configuration below uses 3 m5.large instances, at a cost of $0.096/hour per instance.

This cluster will cost more than $9.31/day ($284/month) for compute resources. This does not include load balancers, data transfer, storage, and potentially other costs. Storage costs start around $50/mo for BKPR and $50/mo per node.
