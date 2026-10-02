# Antigravity Task Execution Plan - Sarrera

- [x] **Phase 1: Environment Preparation**
  - [x] Create directory hierarchy and local volumes (`config/`, `spec/`, `scripts/`, `assets/`, `.antigravity/`).
  - [x] Generate database bootstrap script `config/init-dbs.sql` to initialize `litellm` and `langfuse` databases.
  - [x] Author `.env.example` with required secrets (master keys, DB credentials, salts, MinIO keys).

- [x] **Phase 2: Configuration Generation**
  - [x] Generate `config/litellm-config.yaml` parameterized with 3 compute nodes and Langfuse callbacks.
  - [x] Generate `config/Caddyfile` with TLS/mTLS reverse proxy, security headers, and path-based routing.
  - [x] Assemble `docker-compose.yml` integrating isolated networks (`ai-backend`) and startup healthchecks (`depends_on`).
  - [x] Create IDE client configuration sample `config/vscode-continue-config.sample.json`.

- [x] **Phase 3: Provisioning Automation (CLI Scripts)**
  - [x] Create script `scripts/bootstrap-tiers.sh` to call `/team/new` in LiteLLM for `tier-basic` and `tier-premium`.
  - [x] Create script `scripts/issue-key.sh` accepting `[user_id]` and `[tier]` and returning ready-to-use VS Code Continue JSON.
  - [x] Create validation script `scripts/smoke-test.sh` to verify service health, model routing, and RBAC isolation.

- [x] **Phase 4: Live Deployment & E2E Validation**
  - [x] Spin up the stack via `docker compose up -d`.
  - [x] Run `scripts/bootstrap-tiers.sh` to initialize teams and tiers in LiteLLM.
  - [x] Run `scripts/smoke-test.sh` to verify routing, tier enforcement, and Langfuse telemetry.
