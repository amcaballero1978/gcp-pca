# Network security and isolation: Module overview

The objective:

By the end of this module, you will be able to:

* Design a secure VPC architecture using isolation and appropriate connectivity options (VPC Network Peering, Shared VPC, and Cloud VPN).
* Implement Cloud NGFW policies to filter traffic at layers 3, 4, and 7.
* Configure VPC Service Controls to prevent unauthorized data exfiltration.
* Detect network threats and verify security posture using VPC Flow Logs and Cloud IDS

How they coexist (evaluation order)
These three types of firewalls do not compete; they coexist. Google Cloud evaluates rules in a strict top-down order: 

1 Hierarchical policies first
2 Network policies
3 traditional VPC rules.

Because of this top-down evaluation, your hierarchical policies act as the ultimate guardrail. A local VPC firewall rule can add new restrictions, but it can never alleviate or bypass an inherited restriction. For example, if a hierarchical policy denies all external SSH traffic, a local VPC rule cannot allow it. The hierarchical deny always wins.