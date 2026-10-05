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

## Initial Langfuse Setup & Automated Provisioning

In Sarrera, Langfuse v2 is **fully automated and pre-seeded out-of-the-box**:
- **Platform Administrator**: Created automatically from `.env` (`ADMIN_EMAIL`, default `admin@sarrera.local`).
- **Organization**: Pre-configured as **`Sarrera Platform`**.
- **Audit Project**: Pre-configured as **`Production Gateway`** (`id: proj_sarrera_default`).
- **Pre-linked API Keys**: LiteLLM is pre-configured with `LANGFUSE_PUBLIC_KEY` and `LANGFUSE_SECRET_KEY` matching the seeded database credentials. No manual copy-pasting is required.

---

## 🔑 Single Sign-On (SSO) Bridge

Administrators can access the Langfuse Audit Suite without manually typing credentials via the Sarrera SSO Bridge:

### Access Methods
1. **From Sarrera Admin Portal**:
   - Navigate to **Platform Services** -> Click **Langfuse Audit Suite** or **Single Sign-On (SSO)**.
2. **Direct Browser URL**:
   - 👉 **`https://audit.localhost/sso`** (or `https://audit.{$DOMAIN}/sso`)

### How the SSO Bridge Works
Langfuse uses NextAuth.js for session management, requiring anti-CSRF token verification and secure cookies (`__Secure-next-auth.session-token`). Sarrera's dedicated SSO bridge page (`assets/sso-langfuse.html`) automates this interaction:

1. **Active Session Detection**: Verifies if the browser already holds a valid NextAuth session by querying `/api/auth/session`. If active, it redirects immediately to the project dashboard.
2. **CSRF Negotiation**: Obtains an authentic CSRF token from `/api/auth/csrf`.
3. **Automated Credential Handshake**: Asynchronously issues a `POST` request to `/api/auth/callback/credentials` carrying the bootstrapped admin credentials and CSRF token.
4. **Session Cookie Injection & Project Landing**: NextAuth validates the request against PostgreSQL (`ai-postgres`), sets the secure session cookie, and the bridge redirects the browser directly to the production traces screen:
   ```text
   https://audit.localhost/project/proj_sarrera_default
   ```

---

## 📊 Telemetry & Audit Observability

Every request dispatched through Sarrera's OpenAI Gateway (`litellm-proxy`) is recorded in Langfuse:

| Metric / Attribute | Description | Use Case |
| :--- | :--- | :--- |
| **`trace.id`** | Unique request identifier | Correlates client IDE requests with backend GPU inference logs |
| **`user_id`** | Developer identity or API key hash | Identifies the engineer who executed the completion |
| **`tags`** | `client_group`, `tier-standard`, `team` | Enables multi-tenant cost rollups and corporate invoicing |
| **`latency`** | Total execution time & TTFT | Measures compute node responsiveness and GPU saturation |
| **`tokens`** | Prompt, completion, and total tokens | Verifies monthly quota consumption and spend caps |

---

## 🗄️ Storage Architecture (PostgreSQL + MinIO)

Langfuse in Sarrera is configured with dual-tier enterprise storage:
- **PostgreSQL 16 (`ai-postgres`)**: Indexes traces, observation timestamps, user IDs, token counts, and cost metadata for sub-millisecond search and filtering.
- **MinIO S3 (`ai-minio`)**: Persists large raw trace payloads, completions, and prompt JSON blobs in the `langfuse-traces` bucket, preventing database bloat and ensuring long-term audit trail retention.
