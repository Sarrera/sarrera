# Environment Variables & Secrets Reference

All runtime secrets and deployment variables are centralized in the `.env` file at the root of the repository.

---

## Variable Reference Table

### Core Network & Domain

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `DOMAIN` | `localhost` | Primary domain name handled by Caddy. For production, set to your corporate FQDN (e.g., `ai.company.local`). |

---

### Database Configuration (PostgreSQL 16)

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `POSTGRES_USER` | `platform_admin` | Master administrative user for PostgreSQL. |
| `POSTGRES_PASSWORD` | `DBMasterPass2026_ChangeMe` | Root database password. Should be randomized in production. |
| `POSTGRES_DB` | `postgres` | Default initial connection database name. |

---

### Object Storage (MinIO S3)

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `MINIO_ROOT_USER` | `minio_admin` | Administrative account for MinIO storage. |
| `MINIO_ROOT_PASSWORD` | `minio_password_ChangeMe` | Administrative password for MinIO. |

---

### Initial Platform Administrator (Bootstrapped via Docker Compose)

These credentials configure the primary administrator account across all frontend and backend services on initial startup:

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `ADMIN_USERNAME` | `admin` | Administrator username used for LiteLLM Proxy UI (`/admin/litellm/` or `:4000/ui`). |
| `ADMIN_EMAIL` | `admin@sarrera.local` | Initial admin email automatically seeded into Open WebUI on first boot (`WEBUI_ADMIN_EMAIL`). |
| `ADMIN_PASSWORD` | `sk-master-platform-key-change-me` | Root administrative password used for Open WebUI (`WEBUI_ADMIN_PASSWORD`), LiteLLM UI (`UI_PASSWORD`), and Sarrera Portal. |
| `ADMIN_NAME` | `Platform Administrator` | Display name assigned to the initial admin user in Open WebUI. |
| `LITELLM_MASTER_KEY` | `sk-master-platform-key-change-me` | Root cryptographic master key (must start with `sk-`) used for administrative API endpoints, virtual key issuance, tier creation, and Sarrera Portal `/admin` login. |
| `STORE_MODEL_IN_DB` | `True` | Instructs LiteLLM to persist model schemas, teams, and virtual keys in PostgreSQL. |

---

### Langfuse Telemetry & Observability

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `NEXTAUTH_SECRET` | *(Random 32+ char string)* | Cryptographic salt used for session encryption. |
| `NEXTAUTH_URL` | `http://localhost:3000` | Canonical URL used by Langfuse authentication callbacks. |
| `SALT` | `local_salt_for_keys_change_me` | Salt used by Langfuse to hash API keys. |
| `TELEMETRY_ENABLED` | `false` | Disables telemetry reporting to external Langfuse cloud servers. |
| `LANGFUSE_PUBLIC_KEY` | `pk-lf-setup-key` | Project API public key generated inside Langfuse. |
| `LANGFUSE_SECRET_KEY` | `sk-lf-setup-key` | Project API secret key generated inside Langfuse. |

---

### Open WebUI & Directory Services

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `OPENWEBUI_SECRET_KEY` | `openwebui_secret_change_me` | Session encryption secret for Open WebUI. |
| `ENABLE_LDAP` | `false` | Set to `true` to enable Active Directory / LDAP authentication. |
| `LDAP_SERVER_HOST` | `ldap://dc.company.local` | IP or hostname of the LDAP server. |
| `LDAP_SERVER_PORT` | `389` | Standard LDAP port (`389`) or LDAPS (`636`). |
| `LDAP_BASE_DN` | `DC=company,DC=local` | Base distinguished name for user lookups. |
| `LDAP_SEARCH_FILTER` | `(sAMAccountName={username})` | Filter pattern for Active Directory logins. |

---

### Upstream Inference Node Hosts

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `GPU_PREMIUM_HOST` | `http://gpu-premium-node:11434` | Host serving 32B+ and reasoning models. |
| `GPU_ENTRY_HOST` | `http://gpu-entry-node:11434` | Host serving 7B standard coding models. |
| `CPU_CLUSTER_HOST` | `http://cpu-cluster-node:11434` | Host serving fallback/smoothing 7B models. |
