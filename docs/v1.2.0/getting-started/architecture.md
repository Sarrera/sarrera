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

## System Components

### 1. Reverse Proxy & Edge Router (`ai-caddy`)
- **Technology**: Caddy v2 (`caddy:2-alpine`)
- **Role**: Perimeter security, TLS certificate lifecycle, mTLS enforcement (optional), and path-based request dispatching.
- **Port Bindings**: Ports `80` (HTTP auto-redirect to HTTPS) and `443` (HTTPS).
- **Security**: Strips sensitive internal backend headers, injects strict transport security (`HSTS`), frame options, and content security policy headers.

### 2. AI Gateway & RBAC Controller (`ai-gateway`)
- **Technology**: LiteLLM Proxy (`ghcr.io/berriai/litellm:main-latest`)
- **Role**:
  - Implements the standard OpenAI REST API (`/v1/chat/completions`, `/v1/models`, `/v1/embeddings`).
  - Manages subscription Tiers as LiteLLM **Teams**.
  - Issues and validates virtual API keys (`sk-...`) against PostgreSQL.
  - Dynamically routes requests across upstream GPU/CPU nodes using `least-busy` algorithm.
  - Dispatches non-blocking telemetry callbacks to Langfuse.

### 3. Observability & Audit Engine (`ai-langfuse`)
- **Technology**: Langfuse v2 (`ghcr.io/langfuse/langfuse:2`)
- **Role**: Real-time auditing of LLM interactions.
- **Metrics Captured**:
  - Raw prompt and completion strings for compliance and security auditing.
  - Exact token counts (`prompt_tokens`, `completion_tokens`, `total_tokens`).
  - Request latency and Time-to-First-Token (TTFT).
  - Department and User ID attribution for internal cost chargeback.

### 4. Interactive Chat & Portal (`ai-webui`)
- **Technology**: Open WebUI (`ghcr.io/open-webui/open-webui:main`)
- **Role**: Enterprise web interface for non-developer end users, prompt engineers, and business teams.
- **Features**: Model selection based on permissions, chat history, system prompts, file attachments, and Active Directory / LDAP authentication support.

### 5. Persistent State & Storage Layer
- **PostgreSQL 16 (`ai-postgres`)**:
  - Database `litellm`: Stores virtual keys, spend records, team definitions, user budgets, and routing tables.
  - Database `langfuse`: Stores audit traces, observations, user profiles, and organization analytics.
- **MinIO S3 (`ai-minio`)**:
  - High-performance, S3-compatible object storage used by Langfuse to store large trace payloads, media, and audit attachments.

---

## Network Isolation

The Docker Compose configuration enforces dual-tier network isolation:

1. **`ai-frontend` (Bridge Network)**:
   - Contains `ai-caddy`, `ai-gateway`, `ai-webui`, and `ai-langfuse`.
   - Used for routing incoming HTTP/HTTPS traffic.
2. **`ai-backend` (Bridge Network - Internal)**:
   - Contains `ai-postgres`, `ai-minio`, `ai-gateway`, and `ai-langfuse`.
   - Databases and object storage are never exposed directly to external networks or client machines.
