# Sarrera Platform - Release History & Changelog

This document mirrors the official [Sarrera Documentation Changelog](docs/operations/changelog.md).

---

## [v1.2.0] — 2026-10-03

### 🚀 Enhancements & New Features (MINOR)
* **Caddy Single Sign-On (SSO) & Trusted Header Authentication**:
  * Unified SSO perimeter via Caddy reverse proxy: Injects verified identity headers (`X-User-Email`, `X-User-Name`, `X-User-Role`, `X-User-Groups`) to Open WebUI.
  * Automatic session synchronization across Sarrera Portal, Open WebUI, and Langfuse with zero-friction sign-in and direct platform admin console access.
  * Resolved single-page app (SPA) asset collisions on apex domain by routing to dedicated subdomains (`chat.localhost`, `audit.localhost`, `storage.localhost`) with clean HTTP 302 redirects.
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
* **Flutter Web Governance Portal**: Production-ready UI served natively by Caddy at `/var/www/portal`.
* **Public Landing Page (`/`)**: Value proposition, subscription tiers, interactive IDE setup tabs.
* **Role-Based Authentication (`/login`)**: Developers (`sk-...`) vs Administrators (Master Key).
* **Personal Developer Workspace (`/my-portal`)**: Spend meter, rate limits, whitelisted models.
* **Automated Administrator Provisioning**: Open WebUI and LiteLLM auto-provisioned from `.env`.

---

## [v1.0.0] — 2026-10-01

### 🌟 Initial Platform Release (MAJOR)
* **Consolidated Docker Compose Architecture**: Single `docker-compose.yml` for Caddy, LiteLLM, Langfuse, Open WebUI, PostgreSQL, MinIO, and Ollama.
* **Caddy Reverse Proxy Perimeter**: Unified TLS termination (ports 80/443), security headers, and reverse proxy routing.
* **LiteLLM Gateway & 3-Tier Governance**: `tier-basic`, `tier-standard`, `tier-premium`.
* **Langfuse Observability & Audit Suite**: Distributed LLM trace logging, token cost tracking, MinIO S3 blob storage.
* **Open WebUI Chat Portal**: Multi-user conversational interface connected to LiteLLM `/v1`.
