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
         ┌────────────────────────┬────────────┴────────────┬────────────────────────┐
         ▼                        ▼                         ▼                        ▼
┌──────────────────┐    ┌──────────────────┐      ┌──────────────────┐     ┌──────────────────┐
│  Open WebUI      │    │  LiteLLM Proxy   │      │  Langfuse v2     │     │  MinIO Console   │
│  (Chat Portal)   │    │  (Gateway/Admin) │      │  (Observability) │     │  (Trace Storage) │
│  Internal :8080  │    │  Internal :4000  │      │  Internal :3000  │     │  Internal :9001  │
└──────────────────┘    └──────────────────┘      └──────────────────┘     └──────────────────┘
```

The Central Portal is powered by a high-performance **Flutter Web Application** (compiled to static assets served by Caddy at `/`):
- **Executive KPI Dashboard**: Live tracking of pooled token spend, quota utilization percentages, active keys, and compute cluster health.
- **Subscription Tiers & Quota Governance**: Fine-grained sliders to dynamically adjust monthly budgets (EUR), RPM/TPM limits, and model whitelists for `tier-basic`, `tier-standard`, and `tier-premium`.
- **User Identity & Onboarding Directory**: Searchable developer directory, department attribution, user creation, and instant virtual API key generation with ready-to-paste VS Code Continue (`~/.continue/config.json`) configuration snippets.
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

To prevent asset collisions across different Single Page Applications (SPAs), Caddy supports **both** clean subdomains and subpaths:

| Service | Subdomain Route | Subpath Route | Internal Destination |
| :--- | :--- | :--- | :--- |
| **Sarrera Portal Screen** | `https://localhost/` | `/` | `/var/www/portal/index.html` |
| **Open WebUI (Chat Portal)** | `https://chat.localhost/` | `/chat/*` | `open-webui:8080` |
| **LiteLLM Admin Console** | `https://gateway.localhost/ui/` | `/admin/litellm/*` | `litellm:4000` |
| **Langfuse Observability** | `https://audit.localhost/` | `/admin/audit/*` | `langfuse:3000` |
| **Documentation Portal** | `https://docs.localhost/` | `/docs/*` | Static Docsify Engine |
| **MinIO S3 Storage Console** | `https://storage.localhost/` | `/admin/storage/*` | `minio:9001` |
| **OpenAI Inference API** | `https://gateway.localhost/v1/*` | `/v1/*` | `litellm:4000/v1/*` |

---

---

## 🔑 Single Sign-On (SSO) & Trusted Header Authentication

Caddy serves as the unified identity gateway and SSO coordinator for the entire platform:

### Open WebUI Unified SSO
- **Reverse Proxy Header Injection**: When an authenticated administrator or developer navigates to Open WebUI (`https://chat.localhost/` or `https://chat.{$DOMAIN}/`), Caddy intercepts the request and injects trusted identity headers:
  - `X-User-Email`: Injected from `sarrera_user_email` session cookie or the bootstrapped `${ADMIN_EMAIL}`.
  - `X-User-Name`: Injected from `sarrera_user_name` or `${ADMIN_NAME}`.
  - `X-User-Role`: Injected from `sarrera_user_role` (`admin` or `user`).
- **Zero-Friction Login**: Open WebUI automatically signs the user in via its trusted header auth adapter (`WEBUI_AUTH_TRUSTED_EMAIL_HEADER`), assigns the correct role, issues a persistent JWT session, and displays the chat UI without prompting for separate credentials.
- **Spoofing Protection**: Caddy automatically strips untrusted inbound `X-User-*` headers from external clients before setting verified values.

### Langfuse Audit Suite Single Sign-On & Access Control
- **NextAuth Reverse Proxy Alignment**: Configured with `AUTH_TRUST_HOST=true` and `NEXTAUTH_URL=https://audit.${DOMAIN:-localhost}`.
- **Bootstrapped Platform Admin**: The platform administrator (`${ADMIN_EMAIL}`, default `admin@sarrera.local`) is seeded in PostgreSQL as a global `admin=true` user and assigned as `OWNER` of the default `Sarrera Platform` organization and `Production Gateway` project.
- **Subdomain Routing & CSRF Safety**: Requests sent to `/admin/audit/` on the apex domain are 302-redirected to `https://audit.localhost/` (or `https://audit.{$DOMAIN}/`) to ensure proper NextAuth CSRF protection and eliminate SPA asset collisions with Flutter.

---

## 🛡️ Perimeter Isolation Guarantee

In [`docker-compose.yml`](file:///Users/mario/repositorios/sarrera/docker-compose.yml):
- Only `caddy` binds to `0.0.0.0:80` and `0.0.0.0:443`.
- Internal services (`litellm`, `langfuse`, `open-webui`, `minio`, `postgres`) are either attached exclusively to the private Docker bridge network (`ai-backend`) or bound only to the local loopback interface (`127.0.0.1`).
- Outside network scanners, unauthorized clients, or internet traffic cannot reach internal databases or admin consoles directly. Everything is forced through Caddy's authentication, TLS termination, and security headers.
