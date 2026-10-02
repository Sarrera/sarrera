---
title: "Building Sarrera: Self-Hosted Enterprise AI Inference Gateway with RBAC, Token Quotas & Telemetry"
published: false
description: "How to deploy a private, local AI gateway for engineering teams using LiteLLM, Caddy, Langfuse, and Open WebUI with multi-tier quotas."
tags: ai, devops, docker, opensource
canonical_url: https://github.com/Sarrera/sarrera
cover_image: https://raw.githubusercontent.com/Sarrera/sarrera/main/assets/cover-devto.jpg
---

Engineering teams worldwide face a common dilemma when adopting generative AI:

1. **Cloud AI privacy & security risks**: Sending proprietary source code to third-party APIs (OpenAI, Anthropic) triggers compliance alarms.
2. **Uncontrolled cloud billing**: A handful of developers running autonomous agents (Cline, Roo Code, Cursor) can easily run up thousands of dollars in surprise monthly token bills.
3. **Hardware fragmentation**: On-premise clusters often consist of heterogeneous hardware—a few servers with NVIDIA A100/RTX 4090s, some mid-range workstation GPUs (RTX 3060/4060), and fallback CPU clusters. Without smart routing, high-end GPUs saturate while other machines sit idle.

To solve this, we built and open-sourced **[Sarrera](https://github.com/Sarrera/sarrera)** (*"Entryway / Portal"* in Basque) — an enterprise local AI inference gateway, access control (RBAC), and observability platform packaged into a single Docker Compose deployment.

In this article, I will walk you through the architecture, multi-tier subscription quotas, dynamic node management, and how you can deploy your own private AI hub in under 5 minutes.

---

## 🏛️ High-Level Architecture

Sarrera decouples client IDEs from physical compute hardware, shielding your internal network behind a single perimeter reverse proxy.

```text
                                [ Internet / Corporate LAN ]
                                              │
                                              ▼ (Ports 80 / 443 Only)
                             ┌───────────────────────────────────┐
                             │       ai-caddy (Caddy v2)         │
                             │  - Central TLS Termination        │
                             │  - Sarrera Service Hub & Portal   │
                             │  - Security Headers (HSTS)        │
                             └─────────────────┬─────────────────┘
                                               │
         ┌────────────────────────┬────────────┴────────────┬────────────────────────┐
         ▼                        ▼                         ▼                        ▼
┌──────────────────┐    ┌──────────────────┐      ┌──────────────────┐     ┌──────────────────┐
│  Open WebUI      │    │  LiteLLM Proxy   │      │  Langfuse v2     │     │  MinIO Console   │
│  (Chat Portal)   │    │  (Gateway/Admin) │      │  (Observability) │     │  (Trace Storage) │
│  Internal :8080  │    │  Internal :4000  │      │  Internal :3000  │     │  Internal :9001  │
└──────────────────┘    └─────────┬────────┘      └──────────────────┘     └──────────────────┘
                                  │
                 ┌────────────────┼────────────────┐
                 ▼ (least-busy)   ▼                ▼
          [GPU Premium]    [GPU Standard]    [CPU Cluster]
         (A100 / RTX 4090) (RTX 3060/4060)  (AVX-512 CPU)
           :11434           :11434            :11434
```

### The 7 Core Building Blocks

1. **Edge Reverse Proxy (`Caddy v2`)**: Serves as the single exposed internet entrypoint on ports 80/443. Manages automated TLS certificate lifecycles (Let's Encrypt / ZeroSSL / Internal CA), and serves the integrated Sarrera Service Hub.
2. **AI Gateway & Router (`LiteLLM Proxy`)**: Standard `/v1/chat/completions` OpenAI-compatible API gateway. Enforces subscription Tiers, virtual API keys, and weighted `least-busy` load balancing.
3. **Observability & Auditing (`Langfuse v2`)**: Asynchronous, non-blocking telemetry engine recording every prompt, completion, Time-To-First-Token (TTFT), token sum, and department cost attribution.
4. **Chat & Prompt Portal (`Open WebUI`)**: Interactive chat interface for non-developer staff, document RAG, and Active Directory / LDAP authentication.
5. **Relational State (`PostgreSQL 16`)**: Dedicated persistent databases for LiteLLM keys/budgets and Langfuse trace metadata.
6. **Object Storage (`MinIO S3`)**: High-performance S3 storage bucket retaining large trace payloads and prompt attachments.
7. **Local Stand-in Engine (`Ollama`)**: Local container with network aliases (`gpu-entry-node`, `cpu-cluster-node`, `gpu-premium-node`) for instant testing without external GPU dependencies.

---

## 🛡️ 3-Tier Subscription & Token Quota Governance

To avoid budget blowouts, Sarrera maps developer virtual API keys to **LiteLLM Teams** representing corporate subscription tiers:

```text
┌───────────────────────────────────────────────────────────────────────────────┐
│                           SARRERA SUBSCRIPTION TIERS                          │
├───────────────────────┬───────────────────────────────┬───────────────────────┤
│      tier-basic       │         tier-standard         │     tier-premium      │
│   (Junior / Entry)    │        (Pro / Standard)       │     (Lead / Expert)   │
├───────────────────────┼───────────────────────────────┼───────────────────────┤
│ • basic-coder (7B)    │ • basic-coder (7B)            │ • basic-coder (7B)    │
│                       │ • premium-coder (32B)         │ • premium-coder (32B) │
│                       │                               │ • premium-reasoning   │
│                       │                               │   (DeepSeek-R1)       │
├───────────────────────┼───────────────────────────────┼───────────────────────┤
│ Budget: 15 EUR/month  │ Budget: 50 EUR/month          │ Budget: 100 EUR/month │
│ 60 RPM · 30k TPM      │ 120 RPM · 60k TPM             │ 180 RPM · 120k TPM    │
└───────────────────────┴───────────────────────────────┴───────────────────────┘
```

### Sub-Millisecond Enforcement

When a developer in VS Code triggers autocomplete:
1. LiteLLM checks if the requested model is whitelisted for their tier.
2. If a junior developer with `tier-basic` requests `premium-reasoning` (DeepSeek-R1), the gateway immediately returns **`HTTP 403 Forbidden`** in **10 milliseconds** without touching the GPU cluster.
3. If accumulated monthly spend exceeds the team's cap, it returns `HTTP 400 Budget Exceeded`.
4. If rate limits are exceeded, it returns `HTTP 429 Too Many Requests`.

---

## ⚡ Heterogeneous Load Balancing: Do You Need HAProxy?

A frequent question from infrastructure engineers is: *"Do we need HAProxy or Nginx to balance traffic across our inference servers?"*

**The short answer is NO.** Traditional Layer 4 / Layer 7 proxies like HAProxy only see HTTP byte streams and status codes. They do not understand:
- VRAM memory footprints per request.
- The difference between a 20-token autocomplete versus a 4,000-token multi-file refactoring.
- Token streaming (`text/event-stream`), TTFT latencies, or Out-Of-Memory (OOM) GPU states.

LiteLLM is an **LLM-aware Application Router**. In [`config/litellm-config.yaml`](https://github.com/Sarrera/sarrera/blob/main/config/litellm-config.yaml):

```yaml
model_list:
  # Route 1: Mid-range dedicated GPU (RTX 4060)
  - model_name: basic-coder
    litellm_params:
      model: ollama/qwen2.5-coder:7b
      api_base: http://192.168.1.50:11434
      weight: 8
      rpm: 60

  # Route 2: Fallback CPU cluster
  - model_name: basic-coder
    litellm_params:
      model: ollama/qwen2.5-coder:7b
      api_base: http://192.168.1.51:11434
      weight: 2
      rpm: 20

router_settings:
  routing_strategy: "least-busy"
  timeout: 45
  num_retries: 2
```

- **`least-busy` routing**: Dynamically tracks active requests in flight and routes the next query to the least saturated host.
- **Failover & Retries (`num_retries: 2`)**: If a GPU server crashes or encounters a kernel stall, LiteLLM transparently retries the query against the alternate node before returning an error to the developer.

---

## 🖥️ Live Dynamic Node Administration (Zero-Downtime)

Editing configuration files and restarting containers during office hours is impractical. 

We built an **Authenticated Admin Control Center** directly into the Caddy web interface (`https://localhost/`):

1. Click **`🔐 Admin Control Panel`** in the top navigation.
2. Sign in with the credentials defined in `.env` (`ADMIN_USERNAME` and `ADMIN_PASSWORD`).
3. You can:
   - **Register new GPU/CPU nodes on the fly**: Provide the node IP (`api_base`), backend model, engine (Ollama, vLLM, TGI), weight, and RPM limits.
   - **Ping & test latency**: Verify network connectivity before saving.
   - **Persist in PostgreSQL**: Saves the node directly into LiteLLM without touching YAML files or restarting Docker.
   - **Issue scoped developer keys**: Create keys for `tier-basic`, `tier-standard`, or `tier-premium` with one click.

---

## 💻 Developer Client Integration (VS Code Continue)

Developers consume the platform just like OpenAI:

In `~/.continue/config.json`:

```json
{
  "models": [
    {
      "title": "Sarrera (tier-standard)",
      "provider": "openai",
      "model": "premium-coder",
      "apiKey": "sk-your-virtual-key-here",
      "apiBase": "https://ai.company.local/v1"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Sarrera Autocomplete",
    "provider": "openai",
    "model": "basic-coder",
    "apiKey": "sk-your-virtual-key-here",
    "apiBase": "https://ai.company.local/v1"
  }
}
```

Every autocomplete and chat interaction appears in **Langfuse** in real time:

- Exact prompt and generated code snippet.
- Exact tokens consumed (`prompt_tokens`, `completion_tokens`).
- Time-To-First-Token (TTFT) and total latency.
- Tagged with the developer's username and department for monthly chargeback.

---

## 🚀 Quickstart: Deploy in 5 Minutes

### 1. Clone & Configure
```bash
git clone https://github.com/Sarrera/sarrera.git
cd sarrera
cp .env.example .env
```

### 2. Launch the Stack
```bash
docker compose up -d
```

### 3. Bootstrap the 3 Subscription Tiers
```bash
./scripts/bootstrap-tiers.sh
```

### 4. Issue a Virtual API Key
```bash
./scripts/issue-key.sh alex tier-standard 90d "Core-Engineering"
```

### 5. Run the End-to-End Validation Suite
```bash
./scripts/smoke-test.sh
```

Open **[https://localhost/](https://localhost/)** in your browser to access the Sarrera Central Portal!

---

## 📦 What's Next & Resources

- **GitHub Repository**: [https://github.com/Sarrera/sarrera](https://github.com/Sarrera/sarrera)
- **Documentation Portal**: Hosted on GitHub Pages inside the repository (`/docs`), featuring complete runbooks for Jekyll, Docsify, and MkDocs.

If your organization is exploring private, compliant local AI inference, check out the repository, give it a star ⭐, and let me know your thoughts in the comments!
