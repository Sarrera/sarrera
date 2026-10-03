---
layout: default
title: Home - Sarrera Documentation
nav_order: 1
description: "Sarrera: Enterprise Local AI Inference Gateway, Access Control (RBAC), Token Quotas, and Heterogeneous GPU/CPU Orchestration"
---

# Sarrera Documentation Portal

<p align="center">
  <img src="assets/sarrera-icon.svg" width="120" height="120" alt="Sarrera Logo" />
</p>

<p align="center">
  <b>Enterprise Local AI Inference Gateway, Access Control (RBAC), Token Quotas, and Heterogeneous GPU/CPU Orchestration</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Orchestration-Docker%20Compose-2496ED?logo=docker" alt="Docker Compose" />
  <img src="https://img.shields.io/badge/Gateway-LiteLLM%20Proxy-4B32C3" alt="LiteLLM" />
  <img src="https://img.shields.io/badge/Observability-Langfuse%20v2-000000" alt="Langfuse" />
  <img src="https://img.shields.io/badge/Reverse%20Proxy-Caddy%20v2-1F88C0" alt="Caddy" />
  <img src="https://img.shields.io/badge/Web%20UI-Open%20WebUI-10B981" alt="Open WebUI" />
</p>

---

## 📖 Welcome to Sarrera

**Sarrera** (*"Entryway / Threshold / Portal"* in Basque) is a production-grade, self-hosted platform engineered to deploy a private, secure local AI inference hub for enterprise environments, software engineering teams, and regulated organizations.

It standardizes model access across heterogeneous internal compute clusters (servers equipped with NVIDIA A100/RTX 4090, mid-range GPUs, or CPU nodes running Ollama, vLLM, or TGI), enforces granular role-based access controls (RBAC) with monthly token budgets and rate limits, and provides real-time asynchronous audit telemetry for compliance```text
                                        [ Clients ]
                        VS Code (Continue/Cline) │ Web UI (Chat & Admin)
                                                 │
                                                 ▼
                                     ┌───────────────────────┐
                                     │ Reverse Proxy (Caddy) │ :80 / :443 (TLS/mTLS)
                                     └───────────┬───────────┘
                                                 │
    ┌───────────────────────────┬────────────────┴───────────────────────────┬───────────────────────────┐
    ▼                           ▼                                            ▼                           ▼
┌──────────────────┐  ┌──────────────────┐                         ┌──────────────────┐        ┌──────────────────┐
│  Sarrera Hub     │  │  Open WebUI      │                         │  LiteLLM Proxy   │        │  Ollama Local    │
│  (Flutter Web)   │  │  (Chat / SSO)    │                         │  (Gateway / RBAC)│        │  (Model Engine)  │
│  Static :80/:443 │  │  Internal :8080  │                         │  Internal :4000  │        │  Internal :11434 │
└──────────────────┘  └─────────┬────────┘                         └─────────┬────────┘        └─────────┬────────┘
                                │                                            │                           │
                                │                      ┌─────────────────────┼───────────────────────────┘
                                │                      │ (Async Callback)    │
                                │                      ▼                     ▼
                                │          ┌───────────────────────┐   [GPU Cluster / vLLM Nodes]
                                │          │   Langfuse Observ.    │  (A100 / RTX 4090 / Cloud)
                                │          │   (Prompts & Metrics) │    :11434 / :8000
                                │          │   Internal :3000      │
                                │          └───────────┬───────────┘
                                │                      │
                                └──────────────────┬───┴───────────────┐
                                                   │                   │
                                                   ▼                   ▼
                                       ┌──────────────────┐ ┌──────────────────┐
                                       │   PostgreSQL 16  │ │  MinIO S3 Store  │
                                       │   (DB :5432)     │ │  (Trace Storage) │
                                       └──────────────────┘ └──────────────────┘
```

---

## 🧭 Documentation Map

| Section | Description | Key Topics |
| :--- | :--- | :--- |
| [🚀 Getting Started](getting-started/quickstart.md) | Initial setup and verification | [Quickstart](getting-started/quickstart.md) · [Architecture](getting-started/architecture.md) · [Prerequisites](getting-started/prerequisites.md) |
| [⚙️ Configuration](configuration/docker-compose.md) | Service definitions and environment | [Docker Compose](configuration/docker-compose.md) · [LiteLLM Config](configuration/litellm.md) · [Caddy TLS & SSO](configuration/caddy.md) · [Env Variables](configuration/environment-variables.md) |
| [🛡️ Governance & RBAC](governance-rbac/tiers-and-quotas.md) | Multi-tier policies, tenancy, and keys | [Client Groups & Tenancy](governance-rbac/groups-and-tenancy.md) · [Tiers & Quotas](governance-rbac/tiers-and-quotas.md) · [Key Management](governance-rbac/key-management.md) · [LiteLLM Admin UI](governance-rbac/litellm-dashboard.md) |
| [📊 Observability](observability/langfuse.md) | Auditing and usage telemetry | [Langfuse Setup & SSO](observability/langfuse.md) · [Tracing & Metrics](observability/tracing-and-metrics.md) · [Cost Tracking](observability/cost-accounting.md) |
| [💻 Client Integration](clients/vscode-continue.md) | Connecting developer tooling | [VS Code Continue](clients/vscode-continue.md) · [Cline & Roo Code](clients/cline-and-roo.md) · [Open WebUI](clients/open-webui.md) · [REST API / cURL](clients/curl-api.md) |
| [🖥️ Infrastructure](infrastructure/inference-nodes.md) | Hardware orchestration & local Ollama | [Inference Nodes & Local Engine](infrastructure/inference-nodes.md) · [Load Balancing Policies](infrastructure/load-balancing.md) |
| [🛠️ Operations & Runbooks](operations/scripts-reference.md) | Maintenance and debugging | [CLI Scripts Reference](operations/scripts-reference.md) · [Backup & Maintenance](operations/maintenance.md) · [Troubleshooting](operations/troubleshooting.md) |
| [🏷️ Release & Versioning](operations/versioning.md) | SemVer governance and release history | [Versioning Policy (SemVer)](operations/versioning.md) · [Changelog & History](operations/changelog.md) |

---

## 🔑 Key Features At a Glance

- **OpenAI-Compatible Gateway**: Standard `/v1/chat/completions` API endpoint works out-of-the-box with any standard OpenAI SDK, LangChain, LlamaIndex, or IDE extension.
- **Enterprise Multi-Tenancy & Client Groups**: Support for B2B Corporate Client Groups with pooled budget caps and member-level sub-accounting, alongside B2C Solo Developer subscriptions.
- **6 Platform Services with Automated SSO**: Unified Sarrera Service Hub linking Open WebUI (trusted identity headers), Langfuse v2 (automated NextAuth SSO bridge), LiteLLM Admin Console, Ollama Model Inspector, MinIO Object Storage, and Docsify Docs.
- **Local Heterogeneous Compute Engine**: Containerized local Ollama node (`ai-ollama-local`) supporting `deepseek-r1:14b`, `qwen2.5-coder:32b`, `qwen2.5-coder:7b`, and `qwen2.5-coder:0.5b` with live web inspector at `https://ollama.localhost/`.
- **Subscription Tiers & Quota Controls**: Dynamic multi-tier model (`tier-basic`, `tier-standard`, `tier-premium`) with automatic model whitelisting, monthly token budgets, RPM/TPM rate limits, and real-time spend tracking.
- **Heterogeneous Hardware Routing**: Dynamic `least-busy` load balancing across servers with varying GPU/CPU capacities, with automatic fallback and retry policies.
- **Zero-Latency Audit Logging**: Native asynchronous callbacks to Langfuse record every prompt, response, latency, token count, and department cost tag without blocking client responses.
- **Automated TLS & Security Perimeter**: Single reverse proxy entrypoint using Caddy with internal container network isolation and automatic SSL/TLS termination.
- **Semantic Versioning (SemVer 2.0.0)**: Frozen multi-version documentation snapshots (`docs/vX.Y.Z/`) with GitHub Pages compatibility (`.nojekyll`) and interactive version switcher.
- **Automated CLI Tooling**: Ready-to-run bash scripts for bootstrapping tiers, provisioning user keys, and executing end-to-end smoke tests.
