# Release History & Changelog

All notable changes to the Sarrera Edge Gateway and Governance Platform are documented here following [Semantic Versioning (SemVer)](versioning.md).

---

## [v1.2.0] — 2026-10-03

### 🚀 Enhancements & New Features (MINOR)
* **All 6 Platform Services Integrated in Sarrera Governance Portal**:
  * Added quick-launch console cards and sidebar drawer navigation for all 6 core platform services: Sarrera Governance Portal, Open WebUI Chat Portal, LiteLLM Gateway & Key Proxy, Langfuse v2 Audit Suite, Ollama Local Compute Engine & Inspector, and MinIO S3 Object Storage Console.
* **Ollama Local Compute Engine & Model Inspector (`ollama.localhost`)**:
  * Direct integration of containerized `ai-ollama-local` node into Caddy perimeter routing (`https://ollama.localhost/` and `/admin/ollama/*`).
  * Interactive HTML dashboard (`assets/ollama-dashboard.html`) inspecting model weights (`deepseek-r1:14b`, `qwen2.5-coder:32b`, `qwen2.5-coder:7b`, `qwen2.5-coder:0.5b`), quantization format (`Q4_K_M`), parameter count, and storage sizes.
  * Content-negotiated dual-mode routing in Caddy matching `Accept: text/html` for browser inspection while transparently proxying raw REST API (`/api/tags`, `/api/generate`, `/api/chat`) and OpenAI compatibility layer (`/v1/*`) to `ollama-local:11434`.
* **Automated NextAuth SSO Bridge for Langfuse (`audit.localhost/sso`)**:
  * Automated identity handshake bridge (`assets/sso-langfuse.html`) performing real-time CSRF token negotiation, NextAuth credentials exchange with bootstrapped platform credentials, setting `__Secure-next-auth.session-token`, and auto-navigating straight into `/project/proj_sarrera_default`.
* **Caddy Single Sign-On (SSO) & Trusted Header Authentication**:
  * Unified SSO perimeter via Caddy reverse proxy: Injects verified identity headers (`X-User-Email`, `X-User-Name`, `X-User-Role`, `X-User-Groups`) to Open WebUI.
  * Automatic session synchronization across Sarrera Portal, Open WebUI, and Langfuse with zero-friction sign-in and direct platform admin console access.
  * Resolved single-page app (SPA) asset collisions on apex domain by routing to dedicated subdomains (`chat.localhost`, `audit.localhost`, `storage.localhost`, `ollama.localhost`) with clean HTTP 302 redirects.
  * Fixed Langfuse NextAuth reverse proxy integration (`AUTH_TRUST_HOST=true`, `NEXTAUTH_URL=https://audit.${DOMAIN}`) and bootstrapped initial platform administrator (`admin@sarrera.local`) and default organization/project in PostgreSQL.
* **Client Groups, Solo Tenancy & Dual-Level Billing Rollup**:
  * Added Client Group (`group-*`) governance to LiteLLM with dedicated organizational budget ceilings, aliases, and isolated member key allocations.
  * Implemented Solo Tenancy mode ensuring high-value developers or critical departments operate with dedicated compute quotas without pooled budget contention.
  * Built dual-level billing rollup in the Developer Portal displaying individual key spend alongside collective group consumption.
* **Antigravity Skill: Semantic Versioning & Multi-Version Documentation (`semver-versioning`)**:
  * Built dedicated Antigravity skill in `.agents/skills/semver-versioning/` enforcing SemVer 2.0.0 guidelines:
    * **Patch (1.0.X)**: Minor wording adjustments, typo fixes in instructions/code, non-breaking bug fixes.
    * **Minor (1.X.0)**: Adding new references, guides, compatible capabilities, new endpoints or non-breaking features.
    * **Major (X.0.0)**: Drastic behavioral changes, breaking activation structures, breaking API parameters or architectural shifts.
  * Automated version snapshot generation (`docs/vX.Y.Z/`), navigation synchronization (`_navbar.md`, `index.html`), and codebase manifest updates (`api_constants.dart`, `pubspec.yaml`).

### 🐛 Bug Fixes & Improvements (PATCH)
* **Caddy Upstream Host Preservation**: Replaced `{upstream_hostport}` with `{host}` on reverse proxy blocks to ensure NextAuth and SvelteKit receive accurate client host headers.
* **Cross-Subdomain Session Cookies**: Configured `sarrera_user_*` cookies with domain attributes to enable seamless authentication across `*.localhost` subdomains.

---

## [v1.1.0] — 2026-10-03

### 🚀 Enhancements & New Features (MINOR)
* **Flutter Web Governance Portal**:
  * Deployed a production-ready, zero-overhead Flutter Web UI served natively by Caddy at `/var/www/portal`.
  * Built complete dark-mode design system with curated neon accents, card elevations, and SVG vector branding.
* **Public Landing Page (`/`)**:
  * Added public homepage presenting Sarrera's value proposition, subscription tiers, and quickstarts.
  * Interactive client integration tabs with ready-to-copy configuration for **VS Code Continue**, **Cursor IDE**, **Cline / Roo Code**, and **Python OpenAI SDK**.
* **Role-Based Authentication (`/login`)**:
  * Distinct login paths for **Developers** (Virtual API Key `sk-...`) and **Administrators** (Platform Master Key).
  * Seamless validation against LiteLLM `/admin/litellm/key/info` and `/admin/litellm/team/list`.
* **Personal Developer Workspace (`/my-portal`)**:
  * Real-time monthly token spend progress bar against individual budget caps.
  * Live display of rate limits (RPM / TPM) and whitelisted models for the developer's assigned Tier.
  * Dynamic VS Code Continue `config.json` generator pre-populated with the user's actual Virtual API key.
* **Automated Administrator Provisioning**:
  * Added `ADMIN_USERNAME`, `ADMIN_EMAIL`, `ADMIN_PASSWORD`, and `ADMIN_NAME` to `.env` and `docker-compose.yml`.
  * Open WebUI automatically seeds the primary administrator account on initial startup without requiring manual browser setup.
* **Automated GitHub Pages Deployment**:
  * Configured `.github/workflows/deploy-docs.yml` with `enablement: true` to automatically publish Docsify documentation to `https://sarrera.github.io/sarrera/`.

### 🐛 Bug Fixes & Corrections (PATCH)
* **Font & Icon Resolution**: Fixed Caddy routing conflict where `handle_path /assets/*` intercepted Flutter Web fonts (`MaterialIcons-Regular.otf`), causing missing icons.
* **Cache Invalidation**: Added `@nocache` headers in Caddyfile for `/`, `/index.html`, and `flutter_bootstrap.js` to prevent stale service worker caching.
* **Documentation Links**: Standardized all documentation links across the portal to point directly to the live GitHub Pages site (`https://sarrera.github.io/sarrera/`).

---

## [v1.0.0] — 2026-10-01

### 🌟 Initial Platform Release (MAJOR)
* **Consolidated Docker Compose Architecture**: Single `docker-compose.yml` deploying Caddy, LiteLLM, Langfuse, Open WebUI, PostgreSQL, MinIO, and Ollama.
* **Caddy Reverse Proxy Perimeter**: Unified TLS termination (ports 80/443), security headers, and reverse proxy routing for `/v1/`, `/chat/`, `/admin/audit/`, and `/admin/litellm/`.
* **LiteLLM Gateway & 3-Tier Governance**:
  * Implemented `tier-basic` (7B models, 15 EUR budget), `tier-standard` (7B + 32B models, 50 EUR budget), and `tier-premium` (32B + DeepSeek-R1 reasoning, 100 EUR budget).
  * Hardware routing between standard GPUs and CPU clusters with weighted load balancing.
* **Langfuse Observability & Audit Suite**: Distributed LLM trace logging, token cost tracking, and MinIO S3 blob storage.
* **Open WebUI Chat Portal**: Multi-user conversational interface connected to LiteLLM's unified `/v1` endpoint.
* **Automated CLI Tooling**: Scripts for tier bootstrapping (`bootstrap-tiers.sh`), virtual key issuance (`issue-key.sh`), and end-to-end smoke testing (`smoke-test.sh`).
