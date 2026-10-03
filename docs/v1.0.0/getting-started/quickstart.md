# Quickstart Guide

This guide walks you through deploying Sarrera locally or on an on-premise Linux server in under 5 minutes.

---

## 1. Clone the Repository

Clone the Sarrera repository to your host machine:

```bash
git clone https://github.com/your-org/sarrera.git
cd sarrera
```

---

## 2. Configure Environment Variables

Copy the provided sample environment file:

```bash
cp .env.example .env
```

Review `.env` and configure:
- **Initial Administrator**:
  - **`ADMIN_USERNAME`**: Administrator username (default: `admin`).
  - **`ADMIN_EMAIL`**: Administrator email auto-seeded into Open WebUI (default: `admin@sarrera.local`).
  - **`ADMIN_PASSWORD`**: Master administrative password for Open WebUI and LiteLLM (default: `sk-master-platform-key-change-me`).
  - **`LITELLM_MASTER_KEY`**: Master API key used for LiteLLM proxy and Sarrera Portal admin login.
- **Database & Storage**:
  - **`POSTGRES_PASSWORD`**: Internal database password for PostgreSQL.
  - **`MINIO_ROOT_PASSWORD`**: Root storage password for MinIO S3.
- **Observability**:
  - **`NEXTAUTH_SECRET` & `SALT`**: Random strings used by Langfuse for session encryption.
- **Compute Backends**:
  - **`GPU_*_HOST` / `CPU_CLUSTER_HOST`**: Network address of your upstream Ollama, vLLM, or TGI inference servers.

---

## 3. Launch Services

Start the complete platform in detached mode using Docker Compose:

```bash
docker compose up -d
```

Check the status of all services:

```bash
docker compose ps
```

All 7 core containers should show `Up` (and `healthy` where healthchecks are defined):
- `ai-caddy`
- `ai-gateway` (LiteLLM)
- `ai-langfuse`
- `ai-webui` (Open WebUI)
- `ai-postgres`
- `ai-minio`
- `ai-ollama-local` (optional local stand-in inference server)

---

## 4. Bootstrap Subscription Tiers

Register the default subscription tiers (`tier-basic` and `tier-premium`) with their respective rate limits, model permissions, and budgets in LiteLLM:

```bash
./scripts/bootstrap-tiers.sh
```

Output confirmation:
```text
==========================================================
 Registering Service Tiers in Sarrera (LiteLLM Proxy) 
 Endpoint: http://localhost:4000
==========================================================
[1/2] Registering Basic Tier (tier-basic)...
{
  "team_id": "tier-basic",
  "team_alias": "Basic Dev Subscription", ...
}

[2/2] Registering Premium Tier (tier-premium)...
{
  "team_id": "tier-premium",
  "team_alias": "Premium AI Dev Subscription", ...
}
```

---

## 5. Issue Your First Developer API Key

Generate a scoped virtual API key bound to `tier-basic` or `tier-premium`:

```bash
# Generate key for user "alex" in tier-basic
./scripts/issue-key.sh alex tier-basic 90d "Engineering"
```

The script outputs the generated `sk-...` API key and a ready-to-copy JSON configuration block for VS Code Continue:

```json
{
  "models": [
    {
      "title": "Sarrera (tier-basic)",
      "provider": "openai",
      "model": "basic-coder",
      "apiKey": "sk-1234567890abcdef...",
      "apiBase": "https://localhost/v1"
    }
  ]
}
```

---

## 6. Run Validation Tests

Verify connectivity, model routing, and RBAC isolation:

```bash
./scripts/smoke-test.sh
```

This verifies:
1. LiteLLM gateway liveliness (`HTTP 200`).
2. Langfuse observability API health (`HTTP 200`).
3. Model catalogue registration.
4. RBAC security block: verifies that a `tier-basic` key is rejected (`HTTP 400/403`) when attempting to access a premium model (`premium-coder`).

---

## 7. Web Interfaces Access

| Service | Direct Port | HTTPS (Caddy Proxy) | Default Credentials |
| :--- | :--- | :--- | :--- |
| **Sarrera Portal & Governance** | N/A | [https://localhost/](https://localhost/) | Public Landing / `/admin` (Key: `.env` `LITELLM_MASTER_KEY`) |
| **Open WebUI (Chat Portal)** | [http://localhost:8080](http://localhost:8080) | [https://localhost/chat/](https://localhost/chat/) | Email: `.env` `ADMIN_EMAIL` / Password: `ADMIN_PASSWORD` |
| **LiteLLM Admin Dashboard** | [http://localhost:4000/ui](http://localhost:4000/ui) | [https://localhost/admin/litellm/](https://localhost/admin/litellm/) | User: `ADMIN_USERNAME` / Password: `ADMIN_PASSWORD` |
| **Langfuse Observability** | [http://localhost:3000](http://localhost:3000) | [https://localhost/admin/audit/](https://localhost/admin/audit/) | Admin user initialized on first setup |
| **MinIO Console** | [http://localhost:9001](http://localhost:9001) | Internal | User: `MINIO_ROOT_USER` / Password: `MINIO_ROOT_PASSWORD` |
