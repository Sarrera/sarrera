<p align="center">
  <img src="assets/sarrera-icon.svg" width="110" height="110" alt="Sarrera Logo" />
</p>

<h1 align="center">Sarrera</h1>

<p align="center">
  <b>Enterprise Local AI Inference Gateway, Access Control (RBAC), Token Quotas, and Heterogeneous GPU/CPU Orchestration.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Orchestration-Docker%20Compose-2496ED?logo=docker" alt="Docker Compose" />
  <img src="https://img.shields.io/badge/Gateway-LiteLLM%20Proxy-4B32C3" alt="LiteLLM" />
  <img src="https://img.shields.io/badge/Observability-Langfuse-000000" alt="Langfuse" />
  <img src="https://img.shields.io/badge/Reverse%20Proxy-Caddy%20v2-1F88C0" alt="Caddy" />
  <img src="https://img.shields.io/badge/Web%20UI-Open%20WebUI-10B981" alt="Open WebUI" />
</p>

---

## 🎯 What is Sarrera?

**Sarrera** (*"Entryway / Threshold / Portal"* in Basque) is a comprehensive platform engineered to deploy a private, secure local AI inference hub for enterprise environments and engineering teams.

It centralizes access to Large Language Models (hosted locally on Ollama, vLLM, or TGI), safeguarding underlying hardware from saturation, metering and restricting consumption per user via subscription Tiers, and auditing every interaction in real-time for compliance, governance, and cost observability.

### 🌟 Core Pillars

1. **Universal OpenAI Compatibility**: Serves a standard `/v1/chat/completions` endpoint seamlessly consumable by IDE extensions such as **VS Code (Continue, Cline, Roo Code)** or internal tooling.
2. **Intelligent Heterogeneous Load Balancing**: Dynamically balances inference traffic across servers with high-end GPUs (NVIDIA A100, RTX 4090), mid-range GPUs (RTX 3060/4060), and CPU clusters using weighted `least-busy` routing and fallbacks.
3. **Role-Based Access Control & Billing Tiers (RBAC)**: Segregates users with virtual API keys mapped to teams with strict monthly budgets and permitted model rosters (e.g., `tier-basic` restricted to 7B models vs `tier-premium` granting access to 32B and deep-reasoning models).
4. **Zero-Latency Exhaustive Auditing**: Native, asynchronous integration with **Langfuse** logging complete prompts, completions, exact token counts, latencies (TTFT), and department cost attribution without degrading developer response times.
5. **Collaborative Web Portal**: **Open WebUI** providing chat, agent management, local authentication, and optional integration with **Active Directory / LDAP**.
6. **Perimeter Security & Networking**: Hardened reverse proxy via **Caddy** with automated TLS/mTLS, hiding internal container networks and unifying routing endpoints.

---

## 🏗️ System Topology

```text
                                       [ Clients ]
                       VS Code (Continue/Cline) │ Web UI (Chat & Admin)
                                                │
                                                ▼
                                    ┌───────────────────────┐
                                    │ Reverse Proxy (Caddy) │ :80 / :443 (TLS/mTLS)
                                    └───────────┬───────────┘
                                                │
                 ┌──────────────────────────────┴──────────────────────────────┐
                 │ Internal Dispatch                                           │
                 ▼                                                             ▼
     ┌───────────────────────┐                                     ┌───────────────────────┐
     │      open-webui       │ :8080                               │     litellm-proxy     │ :4000
     │  (Chat / AD Auth)     │                                     │ (OpenAI API / RBAC)   │
     └───────────┬───────────┘                                     └───────────┬───────────┘
                 │                                                             │
                 │                                       ┌─────────────────────┼─────────────────────┐
                 │                                       │ (Async Callback)    │                     │
                 │                                       ▼                     ▼                     ▼
                 │                           ┌───────────────────────┐   [GPU Premium]         [GPU Entry/CPU]
                 │                           │   Langfuse Observ.    │  (A100 / RTX 4090)     (RTX 4060 / CPU)
                 │                           │  (Prompts & Metrics)  │    :11434                :11434
                 │                           └───────────┬───────────┘
                 │                                       │
                 └───────────────────┬───────────────────┘
                                     │
                                     ▼
                     ┌───────────────────────────────┐
                     │         ai-backend net        │
                     │  PostgreSQL (5432)            │
                     │  MinIO S3 (9000/9001)         │
                     └───────────────────────────────┘
```

---

## 📁 Repository Structure

```text
sarrera/
├── .antigravity/
│   └── context.md                        # Autonomous execution context for Antigravity
├── assets/
│   ├── sarrera-icon.svg                  # Official Sarrera vector logo
│   ├── sarrera-icon.png                  # Rendered PNG icon with transparency
│   ├── logo.svg
│   └── logo.png
├── config/
│   ├── Caddyfile                         # Reverse proxy routing, security headers & TLS
│   ├── litellm-config.yaml               # Upstream models, weighted routing & Langfuse callbacks
│   ├── init-dbs.sql                      # Multi-database PostgreSQL bootstrap script
│   └── vscode-continue-config.sample.json# Sample configuration for VS Code Continue
├── scripts/
│   ├── bootstrap-tiers.sh                # CLI script to initialize tiers in LiteLLM
│   ├── issue-key.sh                      # CLI script to issue user virtual API keys by tier
│   └── smoke-test.sh                     # E2E health check and RBAC isolation tests
├── spec/
│   ├── SPEC-architecture.md              # SPEC-001: Architecture & network topology
│   ├── SPEC-infra.md                     # SPEC-002: Compute nodes & balancing policies
│   ├── SPEC-governance-rbac.md           # SPEC-003: Governance, tiers & audit pipeline
│   └── tasks.md                          # Antigravity task execution plan
├── docker-compose.yml                    # Multi-container orchestration stack
├── .env.example                          # Environment variables and secrets template
├── .gitignore                            # Git exclusion rules
└── README.md                             # Main documentation
```

---

## 🚀 Quickstart Guide

### 1. Prerequisites
- Docker Engine 24.0+ and Docker Compose v2.20+.
- Inference backend hosts (servers running Ollama, vLLM, or TGI) reachable over the network.

### 2. Configure Environment Variables
Copy `.env.example` to `.env` and configure your credentials and upstream node endpoints:
```bash
cp .env.example .env
# Edit passwords, Langfuse secrets, and GPU upstream endpoints in .env
```

### 3. Launch Services
Spin up the complete platform in detached mode:
```bash
docker compose up -d
```

Verify the health of the running containers:
```bash
docker compose ps
```

### 4. Initialize Service Tiers
Provision the base teams (`tier-basic` and `tier-premium`) with their respective budgets and rate limits in LiteLLM:
```bash
./scripts/bootstrap-tiers.sh
```

### 5. Issue Virtual API Keys for Developers
Generate a scoped virtual API key for a developer bound to their assigned tier:
```bash
# For Basic Tier (7B models, 15 EUR/month limit):
./scripts/issue-key.sh dev_user tier-basic 90d "Frontend"

# For Premium Tier (32B + R1 reasoning models, 100 EUR/month limit):
./scripts/issue-key.sh dev_senior tier-premium 90d "Core"
```

The script prints the ready-to-use JSON block to paste into the developer's `~/.continue/config.json` for VS Code.

### 6. Run Smoke Tests & Validation
Verify internal connectivity, service health, and RBAC isolation:
```bash
./scripts/smoke-test.sh
```

---

---

## 📚 Complete Documentation Portal (GitHub Pages)

The complete enterprise operations manual, API reference, governance guides, and client setup tutorials are available in the [`docs/`](docs/index.md) directory, pre-configured for **GitHub Pages**:

- [📖 Documentation Portal Home](docs/index.md)
- [🚀 Quickstart Guide](docs/getting-started/quickstart.md)
- [🏗️ System Architecture](docs/getting-started/architecture.md)
- [🛡️ Subscription Tiers & Quotas](docs/governance-rbac/tiers-and-quotas.md)
- [📊 Langfuse Observability & Telemetry](docs/observability/langfuse.md)
- [💻 VS Code Continue Integration](docs/clients/vscode-continue.md)
- [🛠️ CLI Scripts Reference](docs/operations/scripts-reference.md)
- [🔧 Troubleshooting Guide](docs/operations/troubleshooting.md)

### Publishing to GitHub Pages
1. Push your repository to GitHub: `git push origin main`.
2. Go to **Settings** -> **Pages** in your GitHub repository.
3. Under **Build and deployment**, select **GitHub Actions** (the automated workflow in [`.github/workflows/deploy-docs.yml`](.github/workflows/deploy-docs.yml) will build and publish the site automatically) OR choose **Deploy from a branch** and select `/docs`.
4. To preview locally with Docsify:
   ```bash
   python3 -m http.server 8000 --directory docs
   # Open http://localhost:8000 in your browser
   ```

---

## 📖 Detailed Technical Specifications

For formal design documents crafted for Google Antigravity:
- [SPEC-001: General Architecture and Network Topology](spec/SPEC-architecture.md)
- [SPEC-002: Infrastructure and Inference Nodes](spec/SPEC-infra.md)
- [SPEC-003: Governance, Tiers, and Auditing](spec/SPEC-governance-rbac.md)
- [Task Execution Plan](spec/tasks.md)

