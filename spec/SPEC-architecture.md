# SPEC-001: General Architecture and Network Topology

## Status
Approved

## Visual Identity
The project utilizes the visual identifier defined in `assets/logo.svg` and `assets/logo.png`, representing an architectural entryway/threshold (Sarrera in Basque) with a floating nucleus symbolizing tokens and compute requests entering the cluster.

## Flow Diagram and Topology

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

## Components and Internal Ports

| Service | Image | Internal Port | Exposed Port | Role |
| :--- | :--- | :--- | :--- | :--- |
| **caddy** | `caddy:2-alpine` | 80, 443 | 80, 443 | Reverse proxy TLS termination, main router |
| **open-webui**| `ghcr.io/open-webui/open-webui:main` | 8080 | None (via Caddy) | Web UI, Chat, AD/LDAP Auth |
| **litellm** | `ghcr.io/berriai/litellm:main-latest` | 4000 | None (via Caddy) | OpenAI Gateway, RBAC, Heterogeneous router |
| **langfuse** | `ghcr.io/langfuse/langfuse:latest` | 3000 | None (via Caddy) | Tracing, prompt audit, tokens & latency metrics |
| **postgres** | `postgres:16-alpine` | 5432 | None | Persistent storage for LiteLLM & Langfuse |
| **minio** | `minio/minio:latest` | 9000, 9001 | None | S3-compatible backend for Langfuse trace objects |

## Routing in Caddy (`config/Caddyfile`)
- `https://ai.company.local/` -> `open-webui:8080` (Web UI portal)
- `https://ai.company.local/v1/*` -> `litellm:4000/v1/*` (OpenAI-compatible inference API for IDEs)
- `https://ai.company.local/admin/litellm/*` -> `litellm:4000/*` (LiteLLM management dashboard)
- `https://ai.company.local/admin/audit/*` -> `langfuse:3000/*` (Langfuse observability & audit dashboard)
