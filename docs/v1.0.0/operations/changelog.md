# Release History & Changelog

All notable changes to the Sarrera Edge Gateway and Governance Platform are documented here following [Semantic Versioning (SemVer)](versioning.md).

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
