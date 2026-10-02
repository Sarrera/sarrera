# Langfuse Observability & Telemetry

Sarrera uses **Langfuse v2** as its dedicated observability, prompt tracing, and compliance auditing engine.

---

## Architectural Rationale

In high-throughput enterprise environments, synchronous audit logging introduces latency that degrades the interactive coding experience in IDEs. 

Sarrera solves this with an asynchronous callback pattern:
1. **Zero-Latency Ingestion**: The client (VS Code, Cursor, Web UI) sends a request to LiteLLM.
2. **Immediate Client Response**: LiteLLM streams or returns the inference completion directly to the client as fast as the GPU computes it.
3. **Non-blocking Telemetry Dispatch**: Simultaneously, LiteLLM dispatches a non-blocking asynchronous event over the internal Docker network (`http://langfuse:3000`) containing complete prompt and token telemetry.

---

## Initial Langfuse Setup

### 1. Access the Dashboard
- **Direct HTTP URL**: [http://localhost:3000](http://localhost:3000)
- **HTTPS Reverse Proxy URL**: [https://localhost/admin/audit/](https://localhost/admin/audit/)

### 2. Create the Platform Admin Account
On initial startup, navigate to the URL and register the root administrative account with your email and password.

### 3. Generate Project API Keys
1. Create a project named **`Sarrera`**.
2. Navigate to **Settings** -> **API Keys**.
3. Click **"Create new API keys"**.
4. You will receive:
   - `Secret Key`: Begins with `sk-lf-...`
   - `Public Key`: Begins with `pk-lf-...`
   - `Host`: `http://langfuse:3000` (or `https://localhost/admin/audit`)

### 4. Link Keys in `.env`
Update your `.env` file with these generated credentials:
```bash
LANGFUSE_PUBLIC_KEY=pk-lf-xxxx
LANGFUSE_SECRET_KEY=sk-lf-xxxx
```
Restart the LiteLLM container to apply the keys:
```bash
docker compose restart litellm
```

---

## Storage Architecture (PostgreSQL + MinIO)

Langfuse in Sarrera is configured with dual-tier storage:
- **PostgreSQL 16**: Indexes traces, observation timestamps, user IDs, token counts, and cost metadata for sub-millisecond search and filtering.
- **MinIO S3**: Persists large raw trace payloads, completions, and prompt JSON blobs, preventing database bloat and ensuring long-term audit trail retention.
