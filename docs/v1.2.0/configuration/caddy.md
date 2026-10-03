# Caddy Reverse Proxy, Portal & Certificate Management

Caddy serves as the **single perimeter security shield and TLS entrypoint** for the entire Sarrera platform. Only Caddy exposes public ports (`80` and `443`) to the internet or corporate network. All backend containers remain securely isolated within private Docker bridge networks.

---

## 🖥️ The Sarrera Service Hub ("Pantalla de Caddy")

When navigating to the root URL (e.g. `https://localhost/` or `https://ai.company.com/`), Caddy serves the **Sarrera Central Gateway & Service Portal**:

```text
                                [ Internet / Corporate LAN ]
                                              │
                                              ▼ (Port 80 / 443 Only)
                             ┌───────────────────────────────────┐
                             │       ai-caddy (Caddy v2)         │
                             │  - Central TLS Termination        │
                             │  - HSTS & Security Headers        │
                             │  - Sarrera Service Hub Screen     │
                             └─────────────────┬─────────────────┘
                                               │
    ┌──────────────────┬───────────────────────┼───────────────────────┬──────────────────┐
    ▼                  ▼                       ▼                       ▼                  ▼
┌──────────────┐ ┌──────────────┐       ┌──────────────┐        ┌──────────────┐   ┌──────────────┐
│  Open WebUI  │ │ LiteLLM Gate │       │ Langfuse v2  │        │ Ollama Local │   │ MinIO S3     │
│  (Chat / SSO)│ │ (Admin & API)│       │ (SSO & Audit)│        │ (Inspector)  │   │ (Console)    │
│  :8080       │ │ :4000        │       │ :3000        │        │ :11434       │   │ :9001        │
└──────────────┘ └──────────────┘       └──────────────┘        └──────────────┘   └──────────────┘
```

The Central Portal is powered by a high-performance **Flutter Web Application** (compiled to static assets served by Caddy at `/`):
- **Executive KPI Dashboard**: Live tracking of pooled token spend, quota utilization percentages, active keys, and compute cluster health.
- **Subscription Tiers & Quota Governance**: Fine-grained sliders to dynamically adjust monthly budgets (EUR), RPM/TPM limits, and model whitelists for `tier-basic`, `tier-standard`, and `tier-premium`.
- **User Identity & Onboarding Directory**: Searchable developer directory, department attribution, user creation, and instant virtual API key generation with ready-to-paste VS Code Continue (`~/.continue/config.json`) configuration snippets.
- **Client Groups & Multi-Tenancy**: Management of corporate client organizations, pooled group spending caps, and member seat allocations.
- **Platform Services Quick-Launch**: Direct 1-click access to all 6 platform management consoles with automated SSO integration.
- **Telemetry & Spend Observability**: Real-time token consumption meters, cost chargeback leaderboards, and direct links to Langfuse v2 audit suites.
- **Compute Nodes & Dynamic Orchestration**: Live latency ping testing and dynamic registration of upstream Ollama / vLLM nodes persisted in PostgreSQL without container downtime.
- **TLS Certificate Management**: Reference configurations and interactive Caddyfile generator for Internal CA, Public ACME (Let's Encrypt / ZeroSSL), Corporate Wildcard PKI, and DNS-01 challenges.

### Building & Updating the Flutter Portal
The Flutter Web frontend source code lives in [`frontend/`](file:///Users/mario/repositorios/sarrera/frontend/). To recompile and redeploy to Caddy:
```bash
./scripts/build-portal.sh
```
This compiles the release web bundle and automatically reloads Caddy without downtime.

---

## 🔒 Certificate Management Examples

Caddy automates certificate lifecycles, OCSP stapling, and HTTP-to-HTTPS redirects. Depending on your deployment environment, choose one of the following configurations in [`config/Caddyfile`](file:///Users/mario/repositorios/sarrera/config/Caddyfile):

### Example 1: Automated Public ACME (Let's Encrypt / ZeroSSL)
For internet-facing production servers with a registered public domain (e.g., `ai.company.com`):

```caddy
ai.company.com {
    # Supply your admin email for expiration alerts and ACME registration
    tls admin@company.com

    # Modern TLS 1.3 / 1.2 with HSTS
    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
    }

    # Microservice reverse proxies
    handle /v1/* { reverse_proxy litellm:4000 }
    handle /chat/* { reverse_proxy open-webui:8080 }
}
```
*Caddy automatically performs HTTP-01 or TLS-ALPN-01 challenges, provisions valid certificates, and handles renewals without manual intervention.*

---

### Example 2: Custom Enterprise Wildcard Certificate / PKI
For enterprise networks that mandate company-issued certificates signed by an internal corporate Root CA or commercial wildcard:

```caddy
*.ai.company.local, ai.company.local {
    # Specify the absolute paths to your mounted certificates
    tls /etc/caddy/certs/corporate-bundle.crt /etc/caddy/certs/corporate-private.key

    # Reverse proxy definitions...
}
```
*Mount the certificate files into the Caddy container via `docker-compose.yml`:*
```yaml
    volumes:
      - /path/on/host/certs:/etc/caddy/certs:ro
```

---

### Example 3: Internal Self-Signed CA (Default Development Mode)
For local testing or staging environments on `localhost` or private IPs:

```caddy
{$DOMAIN:localhost} {
    # Caddy initializes its own embedded Certificate Authority
    tls internal

    # ...
}
```

---

### Example 4: DNS-01 ACME Challenge (Private Intranets & Air-Gapped)
To issue publicly trusted Let's Encrypt certificates for internal intranet domains without opening port 80 to the internet:

```caddy
ai.internal.corp {
    tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
    }
}
```

---

## 🌐 Centralized Routing Directory

To prevent asset collisions across different Single Page Applications (SPAs), Caddy supports **both** clean subdomains and subpaths across all 6 core platform services:

| Service | Subdomain Route | Subpath Route | Internal Destination | Auth & SSO Behavior |
| :--- | :--- | :--- | :--- | :--- |
| **Sarrera Governance Portal** | `https://localhost/` | `/` | Static Flutter Web (`/var/www/portal`) | Platform Master Auth / Session Cookie |
| **Open WebUI (Chat Portal)** | `https://chat.localhost/` | `/chat/*` | `open-webui:8080` | Trusted Header SSO (`X-User-Email`, `X-User-Role`) |
| **LiteLLM Admin Console** | `https://gateway.localhost/ui/` | `/admin/litellm/*` | `litellm:4000/ui/` | Master Key Bearer Auth (`LITELLM_MASTER_KEY`) |
| **Langfuse Audit Suite** | `https://audit.localhost/` | `/admin/audit/*` *(Redirect)* | `langfuse:3000` | NextAuth Cookie (`__Secure-next-auth.session-token`) |
| **Langfuse Automated SSO** | `https://audit.localhost/sso` | `/admin/audit/sso` | Static SSO Bridge (`assets/sso-langfuse.html`) | Automated CSRF + Credentials Handshake |
| **Ollama Model Inspector** | `https://ollama.localhost/` | `/admin/ollama/*` | Dashboard (`assets/ollama-dashboard.html`) | Web UI (`Accept: text/html`) / Direct API Proxy |
| **Ollama Inference Engine** | `https://ollama.localhost/api/*` | `/admin/ollama/api/*` | `ollama-local:11434` | Direct Local REST / GGUF Tags API |
| **MinIO S3 Storage Console** | `https://storage.localhost/` | `/admin/storage/*` | `minio:9001` | Root Credentials (`MINIO_ROOT_USER`) |
| **OpenAI Inference Gateway** | `https://gateway.localhost/v1/*` | `/v1/*` | `litellm:4000/v1/*` | Virtual API Key (`sk-sarrera-...`) |
| **Documentation Portal** | `https://docs.localhost/` | `/docs/*` | Static Docsify & Markdown Engine | Public Access / Multi-version Nav |

---

## 🔑 Single Sign-On (SSO) & Identity Federation

Caddy serves as the unified identity gateway and SSO coordinator for the entire platform:

### 1. Open WebUI Unified SSO (Trusted Header Flow)
- **Reverse Proxy Header Injection**: When an authenticated administrator or developer navigates to Open WebUI (`https://chat.localhost/` or `https://chat.{$DOMAIN}/`), Caddy intercepts the request and injects trusted identity headers:
  - `X-User-Email`: Injected from `sarrera_user_email` session cookie or the bootstrapped `${ADMIN_EMAIL}`.
  - `X-User-Name`: Injected from `sarrera_user_name` or `${ADMIN_NAME}`.
  - `X-User-Role`: Injected from `sarrera_user_role` (`admin` or `user`).
- **Zero-Friction Login**: Open WebUI automatically signs the user in via its trusted header auth adapter (`WEBUI_AUTH_TRUSTED_EMAIL_HEADER`), assigns the correct role, issues a persistent JWT session, and displays the chat UI without prompting for separate credentials.
- **Spoofing Protection**: Caddy automatically strips untrusted inbound `X-User-*` headers from external clients before setting verified values.

### 2. Langfuse Automated SSO Bridge (`https://audit.localhost/sso`)
- **The Challenge**: Langfuse v2 uses NextAuth with strict CSRF token validation and HTTP-only session cookies (`__Secure-next-auth.session-token`). Simple header injection cannot establish a valid NextAuth session cookie in modern browsers.
- **The Solution - Automated SSO Handshake**:
  Caddy serves the lightweight identity bridge [`assets/sso-langfuse.html`](file:///Users/mario/repositorios/sarrera/assets/sso-langfuse.html) on `https://audit.localhost/sso`:
  1. **Session Check**: Queries `/api/auth/session` via `fetch()`. If a valid NextAuth session already exists, it immediately redirects the browser to the default project (`/project/proj_sarrera_default`).
  2. **CSRF Acquisition**: If unauthenticated, it requests a fresh anti-CSRF token from `/api/auth/csrf`.
  3. **Credentials Exchange**: Automatically issues an asynchronous `POST` to `/api/auth/callback/credentials` with the bootstrapped administrator credentials (`admin@sarrera.local` / master key).
  4. **Cookie Ingestion & Redirect**: NextAuth sets the secure session cookie in the response, and the script redirects the user into the active audit project dashboard (`/project/proj_sarrera_default`), delivering seamless Single Sign-On from the Sarrera Admin Portal.

```mermaid
sequenceDiagram
    autonumber
    actor Admin as Administrator (Portal)
    participant Caddy as Caddy Reverse Proxy
    participant Bridge as SSO Bridge (sso-langfuse.html)
    participant NextAuth as Langfuse NextAuth Engine
    participant DB as PostgreSQL (ai-postgres)

    Admin->>Caddy: Click "Audit Suite" (audit.localhost/sso)
    Caddy->>Bridge: Serve static sso-langfuse.html
    Bridge->>NextAuth: GET /api/auth/session
    NextAuth-->>Bridge: 401 Unauthenticated
    Bridge->>NextAuth: GET /api/auth/csrf
    NextAuth-->>Bridge: { "csrfToken": "abc123xyz" }
    Bridge->>NextAuth: POST /api/auth/callback/credentials (admin@sarrera.local, csrfToken)
    NextAuth->>DB: Verify credentials in public.users
    DB-->>NextAuth: Match confirmed (admin=true, role=OWNER)
    NextAuth-->>Bridge: Set-Cookie: __Secure-next-auth.session-token; 200 OK
    Bridge->>Admin: window.location.replace('/project/proj_sarrera_default')
    Admin->>Caddy: GET /project/proj_sarrera_default (with session-token)
    Caddy->>NextAuth: Proxy request with cookie
    NextAuth-->>Admin: Render Langfuse Project Audit Console
```

---

## 🦙 Ollama Model Engine Inspector (`https://ollama.localhost/`)

Sarrera integrates a local Ollama compute node (`ai-ollama-local`) directly into the perimeter proxy routing. To provide administrators and developers with instant visibility into local weights without needing terminal access, Caddy implements **content-negotiated browser routing**:

### Dual-Mode Routing Architecture
In [`config/Caddyfile`](file:///Users/mario/repositorios/sarrera/config/Caddyfile):

```caddy
ollama.{$DOMAIN:localhost} {
    import security_headers
    tls internal

    # 1. Browser traffic: Serve interactive model inspector
    @browser {
        header Accept *text/html*
        path /
    }
    handle @browser {
        root * /var/www/portal/assets
        rewrite * /ollama-dashboard.html
        file_server
    }

    # 2. Subpath assets fallback
    handle /admin/ollama/* {
        root * /var/www/portal/assets
        rewrite * /ollama-dashboard.html
        file_server
    }

    # 3. Direct API traffic: Proxy to Ollama container
    handle {
        reverse_proxy ollama-local:11434
    }
}
```

### Inspector Capabilities
When opened in a web browser (`https://ollama.localhost/` or from the Sarrera Portal Platform Services menu):
- **Live Model Discovery**: Queries the internal `/api/tags` endpoint and dynamically renders interactive cards for all pulled model weights (e.g. `deepseek-r1:14b`, `qwen2.5-coder:32b`, `qwen2.5-coder:7b`, `qwen2.5-coder:0.5b`).
- **GGUF Parameter & Quantization Inspection**: Displays the parameter size (e.g., `14.8B`, `32.5B`), quantization format (`Q4_K_M`), model family (`qwen2`), and exact disk footprint.
- **1-Click CLI Snippets**: Provides copy-to-clipboard commands (`ollama run <model>`) for rapid terminal interaction.
- **REST Endpoints Guide**: Documents the active `/api/tags`, `/api/generate`, `/api/chat`, and OpenAI-compatible `/v1/chat/completions` routes.

---

## 🛡️ Perimeter Isolation Guarantee

In [`docker-compose.yml`](file:///Users/mario/repositorios/sarrera/docker-compose.yml):
- Only `caddy` binds to `0.0.0.0:80` and `0.0.0.0:443`.
- Internal services (`litellm`, `langfuse`, `open-webui`, `minio`, `ollama-local`, `postgres`) are either attached exclusively to the private Docker bridge network (`ai-backend`) or bound only to the local loopback interface (`127.0.0.1`).
- Outside network scanners, unauthorized clients, or internet traffic cannot reach internal databases or admin consoles directly. Everything is forced through Caddy's authentication, TLS termination, and security headers.
