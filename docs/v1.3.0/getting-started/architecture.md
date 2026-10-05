# Architecture & Topology

Sarrera is structured around a decoupled microservice architecture orchestrated by Docker Compose, isolating internal backend databases and storage behind reverse proxy and gateway layers.

---

## High-Level Topology

```text
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

## System Components

### 1. Reverse Proxy & Perimeter Shield (`ai-caddy`)
- **Technology**: Caddy v2 (`caddy:2-alpine`)
- **Role**: Perimeter security, TLS certificate lifecycle, automated SSO header injection for Open WebUI, SSO bridge for Langfuse (`/sso`), content-negotiated routing for Ollama inspector (`Accept: text/html`), and path/subdomain request dispatching.
- **Port Bindings**: Public ports `80` (HTTP auto-redirect to HTTPS) and `443` (HTTPS).
- **Security**: Strips sensitive internal backend headers, injects strict transport security (`HSTS`), frame options, and content security policy headers.

### 2. Sarrera Central Hub & Governance Portal
- **Technology**: Flutter Web compiled to optimized static assets served directly by Caddy.
- **Role**: Executive KPI dashboards, token budget sliders, user and virtual key provisioning, client group multi-tenancy management, and 1-click single-sign-on access to all platform management consoles.

### 3. AI Gateway & RBAC Controller (`ai-gateway`)
- **Technology**: LiteLLM Proxy (`ghcr.io/berriai/litellm:main-latest`)
- **Role**:
  - Implements the standard OpenAI REST API (`/v1/chat/completions`, `/v1/models`, `/v1/embeddings`).
  - Manages subscription Tiers and Client Groups as LiteLLM **Teams**.
  - Issues and validates virtual API keys (`sk-...`) against PostgreSQL.
  - Dynamically routes requests across upstream GPU/CPU nodes using `least-busy` algorithm.
  - Dispatches non-blocking telemetry callbacks to Langfuse.

### 4. Local Inference Compute Engine (`ai-ollama-local`)
- **Technology**: Ollama Container (`ollama/ollama:latest`)
- **Role**: Runs local GGUF model weights (`deepseek-r1:14b`, `qwen2.5-coder:32b`, `qwen2.5-coder:7b`, `qwen2.5-coder:0.5b`) directly within the Docker stack.
- **Volume Storage**: `ai-ollama-data` mounted at `/root/.ollama` for zero-data-loss model weight persistence.
- **Web Model Inspector**: Content-negotiated browser dashboard at `https://ollama.localhost/` inspecting weights, quantization levels, parameter counts, and disk usage.

### 5. Observability & Audit Engine (`ai-langfuse`)
- **Technology**: Langfuse v2 (`ghcr.io/langfuse/langfuse:2`)
- **Role**: Real-time asynchronous auditing of LLM interactions.
- **Automated Provisioning & SSO**: Pre-seeded administrator account in PostgreSQL with automated CSRF handshake bridge (`https://audit.localhost/sso`).
- **Metrics Captured**:
  - Raw prompt and completion strings for compliance and security auditing.
  - Exact token counts (`prompt_tokens`, `completion_tokens`, `total_tokens`).
  - Request latency and Time-to-First-Token (TTFT).
  - Department, Client Group, and User ID attribution for internal cost chargeback.

### 6. Interactive Chat & Developer Portal (`ai-webui`)
- **Technology**: Open WebUI (`ghcr.io/open-webui/open-webui:main`)
- **Role**: Enterprise web interface for non-developer end users, prompt engineers, and business teams.
- **Single Sign-On**: Zero-friction login via Caddy's trusted identity headers (`X-User-Email`, `X-User-Name`, `X-User-Role`).

### 7. Persistent State & Storage Layer
- **PostgreSQL 16 (`ai-postgres`)**:
  - Database `litellm`: Stores virtual keys, spend records, team definitions, user budgets, and routing tables.
  - Database `langfuse`: Stores audit traces, observations, user profiles, and organization analytics.
- **MinIO S3 (`ai-minio`)**:
  - High-performance, S3-compatible object storage used by Langfuse to store large trace payloads, media, and audit attachments in the `langfuse-traces` bucket.
  - Web console served at `https://storage.localhost/`.

---

## Network Isolation

The Docker Compose configuration enforces dual-tier network isolation:

1. **`ai-frontend` (Bridge Network)**:
   - Contains `ai-caddy`, `ai-gateway`, `ai-webui`, `ai-langfuse`, and `ai-ollama-local`.
   - Used for routing incoming HTTP/HTTPS traffic.
2. **`ai-backend` (Bridge Network - Internal)**:
   - Contains `ai-postgres`, `ai-minio`, `ai-gateway`, `ai-langfuse`, and `ai-ollama-local`.
   - Databases and object storage are never exposed directly to external networks or client machines.
