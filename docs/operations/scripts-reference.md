# Automation Scripts Reference

Sarrera includes production-ready shell scripts in [`scripts/`](file:///Users/mario/repositorios/sarrera/scripts/) to streamline day-to-day administration without manual database manipulation or complex curl payloads.

---

## 1. `scripts/bootstrap-tiers.sh`

### Purpose
Registers the foundational subscription tiers (`tier-basic` and `tier-premium`) in LiteLLM Proxy with predefined quotas, models, and budgets.

### Usage
```bash
./scripts/bootstrap-tiers.sh
```

### Environment Variables Respected
- `LITELLM_URL`: Base URL of LiteLLM (default: `http://localhost:4000`).
- `LITELLM_MASTER_KEY`: Master authentication key.

### What it Executes
Makes two `POST /team/new` requests to LiteLLM:
1. Provisions `tier-basic` with `models: ["basic-coder"]`, `max_budget: 15.0`, `budget_duration: "30d"`, `tpm_limit: 30000`, `rpm_limit: 60`.
2. Provisions `tier-premium` with `models: ["premium-coder", "premium-reasoning", "basic-coder"]`, `max_budget: 100.0`, `budget_duration: "30d"`, `tpm_limit: 120000`, `rpm_limit: 180`.

---

## 2. `scripts/issue-key.sh`

### Purpose
Generates a virtual API key bound to an individual developer or service account, assigning them to a subscription tier and tagging their department for cost tracking.

### Usage
```bash
./scripts/issue-key.sh <user_id> [tier] [duration] [department]
```

### Arguments
- `<user_id>`: **Required**. Developer username, email, or service ID (e.g. `carlos_sainz`).
- `[tier]`: **Optional**. Subscription tier: `tier-basic` (default) or `tier-premium`.
- `[duration]`: **Optional**. Key validity span (e.g. `30d`, `90d`, `365d`). Default: `90d`.
- `[department]`: **Optional**. Cost center tag (e.g. `DataScience`, `Frontend`). Default: `Engineering`.

### Examples
```bash
# Issue standard key for junior engineer
./scripts/issue-key.sh alex tier-basic 60d Frontend

# Issue premium key for tech lead
./scripts/issue-key.sh elena tier-premium 180d Architecture
```

### Output
Prints the raw API key (`sk-...`) along with a ready-to-copy JSON block for `~/.continue/config.json`.

---

## 3. `scripts/create-group.sh`

### Purpose
Provisions a B2B corporate client group in LiteLLM Proxy with pooled monthly token quotas, base tier model inheritance, and multi-seat support.

### Usage
```bash
./scripts/create-group.sh [OPTIONS]
```

### Options
- `-i, --id <slug>`: Client group identifier (auto-prefixed with `group-`).
- `-n, --name <name>`: Corporate company or department name.
- `-t, --tier <tier>`: Base subscription tier (`tier-basic`, `tier-standard`, `tier-premium`). Default: `tier-standard`.
- `-b, --budget <amount>`: Monthly pooled budget in EUR. Default: `500.0`.
- `-e, --email <email>`: Corporate billing contact email.
- `-r, --rpm <rpm>`: Requests per minute rate limit. Default: `120`.

### Example
```bash
./scripts/create-group.sh -i acme-corp -n "Acme Corporation" -t tier-standard -b 500.0 -e billing@acme.com
```

---

## 4. `scripts/build-portal.sh`

### Purpose
Compiles the Flutter Web management portal in release mode and automatically syncs it to Caddy's `/var/www/portal` directory, triggering a hot reload of the reverse proxy perimeter.

### Usage
```bash
./scripts/build-portal.sh
```

---

## 5. `scripts/smoke-test.sh`

### Purpose
An automated validation suite that executes end-to-end integration and security assertions against the live platform.

### Usage
```bash
./scripts/smoke-test.sh
```

### Assertions Executed
1. **[1/4] LiteLLM Gateway Health**: Verifies that `/health/liveliness` or `/health` returns `HTTP 200`.
2. **[2/4] Langfuse Observability Health**: Verifies that `/api/public/health` returns `HTTP 200`.
3. **[3/4] Model Catalogue**: Confirms registered models in LiteLLM `/v1/models`.
4. **[4/4] RBAC Tier Isolation**:
   - Generates a temporary test key in `tier-basic`.
   - Sends an inference request targeting `premium-coder`.
   - Asserts that LiteLLM rejects the unauthorized request with `HTTP 400` or `HTTP 403`.
