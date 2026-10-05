# Docker Compose Configuration

The core deployment of Sarrera is managed through a single, consolidated [`docker-compose.yml`](file:///Users/mario/repositorios/sarrera/docker-compose.yml) file. This architecture avoids fragmented override files and ensures consistent reproducibility across development and production environments.

---

## Service Inventory

```yaml
services:
  caddy:          # Reverse proxy and TLS termination (caddy:2-alpine)
  litellm:        # OpenAI Gateway, RBAC & Load Balancer (litellm:main-latest)
  langfuse:       # Telemetry and audit platform (langfuse:2)
  open-webui:     # Web chat portal (open-webui:main)
  postgres:       # Shared relational database (postgres:16-alpine)
  minio:          # S3-compatible trace blob storage (chainguard/minio)
  ollama-local:   # Stand-in local inference engine (ollama/ollama:latest)
  discovery:      # Prometheus HTTP SD from LiteLLM nodes (python:3.12-alpine)  [since v1.3.0]
  prometheus:     # Hardware & GPU metrics aggregation (prom/prometheus:v2.51.0) [since v1.3.0]
```

---

## Detailed Service Breakdown

### 1. `caddy` (Service: `ai-caddy`)
- **Image**: `caddy:2-alpine`
- **Ports**: `80:80`, `443:443`
- **Volumes**:
  - `./config/Caddyfile:/etc/caddy/Caddyfile:ro` (read-only configuration)
  - `caddy_data:/data` (persists TLS certificates)
  - `caddy_config:/config`
- **Networks**: `ai-frontend`
- **Restart Policy**: `unless-stopped`

### 2. `litellm` (Service: `ai-gateway`)
- **Image**: `ghcr.io/berriai/litellm:main-latest`
- **Command**: `["--config", "/app/config.yaml", "--port", "4000"]`
- **Environment**:
  - `DATABASE_URL`: `postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/litellm`
  - `STORE_MODEL_IN_DB`: `True`
  - `LITELLM_MASTER_KEY`: Root administrative secret (`sk-...`) for managing keys, teams, and Sarrera Portal `/admin` auth.
  - `UI_USERNAME`: `${ADMIN_USERNAME:-admin}` (Administrator username for the LiteLLM proxy UI).
  - `UI_PASSWORD`: `${ADMIN_PASSWORD:-sk-master-platform-key-change-me}` (Administrator password for the LiteLLM proxy UI).
  - `LANGFUSE_PUBLIC_KEY`, `LANGFUSE_SECRET_KEY`, `LANGFUSE_HOST`: Observability callback targets.
  - `GPU_PREMIUM_HOST`, `GPU_ENTRY_HOST`, `CPU_CLUSTER_HOST`: Dynamic upstream node hosts.
- **Volumes**:
  - `./config/litellm-config.yaml:/app/config.yaml:ro`
- **Depends On**:
  - `postgres` (condition: `service_healthy`)

### 3. `langfuse` (Service: `ai-langfuse`)
- **Image**: `ghcr.io/langfuse/langfuse:2`
- **Pinning Rationale**: Langfuse v3 requires ClickHouse. Pinning to major version `2` keeps the infrastructure lightweight and operational on PostgreSQL and MinIO without requiring a heavy ClickHouse cluster.
- **Environment**:
  - `DATABASE_URL`: `postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/langfuse`
  - `NEXTAUTH_URL`: `https://audit.${DOMAIN:-localhost}` (Configured for reverse proxy access)
  - `AUTH_TRUST_HOST`: `true` (Enables NextAuth behind Caddy reverse proxy)
  - S3 configuration (`LANGFUSE_S3_EVENT_UPLOAD_BUCKET`, `LANGFUSE_S3_EVENT_UPLOAD_ENDPOINT`, etc.)
- **Depends On**:
  - `postgres` (condition: `service_healthy`)
  - `minio` (condition: `service_started`)

### 4. `open-webui` (Service: `ai-webui`)
- **Image**: `ghcr.io/open-webui/open-webui:main`
- **Environment**:
  - `OPENAI_API_BASE_URL`: `http://litellm:4000/v1`
  - `OPENAI_API_KEY`: `${LITELLM_MASTER_KEY}`
  - `WEBUI_SECRET_KEY`: `${OPENWEBUI_SECRET_KEY}`
  - `WEBUI_ADMIN_EMAIL`: `${ADMIN_EMAIL:-admin@sarrera.local}` (Auto-provisions the primary admin user on first launch).
  - `WEBUI_ADMIN_PASSWORD`: `${ADMIN_PASSWORD:-sk-master-platform-key-change-me}` (Admin password for chat UI login).
  - `WEBUI_ADMIN_NAME`: `${ADMIN_NAME:-Platform Administrator}`
  - `WEBUI_AUTH_TRUSTED_EMAIL_HEADER`: `X-User-Email` (Single Sign-On header injected by Caddy)
  - `WEBUI_AUTH_TRUSTED_NAME_HEADER`: `X-User-Name`
  - `WEBUI_AUTH_TRUSTED_ROLE_HEADER`: `X-User-Role` (`admin` or `user` role assignment)
  - `WEBUI_AUTH_TRUSTED_GROUPS_HEADER`: `X-User-Groups`
  - `ENABLE_LDAP`: `${ENABLE_LDAP:-false}`
- **Volumes**:
  - `openwebui_data:/app/backend/data`

### 5. `postgres` (Service: `ai-postgres`)
- **Image**: `postgres:16-alpine`
- **Initialization**: Automatically mounts `./config/init-dbs.sql` into `/docker-entrypoint-initdb.d/` to create separate databases for `litellm` and `langfuse` on first boot.
- **Healthcheck**: `pg_isready -U ${POSTGRES_USER}`

### 6. `minio` (Service: `ai-minio`)
- **Image**: `cgr.dev/chainguard/minio:latest`
- **Command**: `server /data --console-address ":9001"`
- **Healthcheck**: Performs an HTTP check on `http://localhost:9000/minio/health/live`.

### 7. `discovery` (Service: `ai-discovery`) — *since v1.3.0*
- **Image**: `python:3.12-alpine` running [`services/discovery/app.py`](https://github.com/Sarrera/sarrera/blob/main/services/discovery/app.py)
- **Role**: Reads registered nodes from LiteLLM (`/model/info`) and serves Prometheus HTTP SD target lists (`/targets/node-exporter`, `/targets/cadvisor`, `/targets/dcgm-exporter`, `/targets/all`).
- **Environment**: `LITELLM_HOST=http://litellm:4000`, `LITELLM_MASTER_KEY`, `PORT=8001`
- **Exposure**: Internal only; proxied by Caddy at `/admin/discovery/*`.

### 8. `prometheus` (Service: `ai-prometheus`) — *since v1.3.0*
- **Image**: `prom/prometheus:v2.51.0`
- **Command**: `--config.file=/etc/prometheus/prometheus.yml --storage.tsdb.retention.time=15d --web.enable-lifecycle`
- **Volumes**: `./config/prometheus.yml` (read-only), `prometheus_data:/prometheus`
- **Ports**: `127.0.0.1:9090:9090`; public via `https://prometheus.localhost/` and `/admin/prometheus/*`.
- **Depends On**: `discovery`
- See [Hardware Telemetry with Prometheus](observability/prometheus-telemetry.md).

---

## Volume Management

The stack uses named volumes to ensure data persistence across container updates and restarts:

| Volume Name | Target Path | Data Content |
| :--- | :--- | :--- |
| `postgres_data` | `/var/lib/postgresql/data` | LiteLLM budgets/keys & Langfuse metadata |
| `minio_data` | `/data` | S3 raw trace payloads and blobs |
| `openwebui_data` | `/app/backend/data` | Chat conversations, users, uploaded documents |
| `caddy_data` | `/data` | SSL/TLS certificates and ACME account keys |
| `caddy_config` | `/config` | Caddy runtime configuration cache |
| `ollama_data` | `/root/.ollama` | Local quantized LLM weights (`.gguf`) |
| `prometheus_data` | `/prometheus` | Hardware/GPU time series, 15-day retention *(since v1.3.0)* |
