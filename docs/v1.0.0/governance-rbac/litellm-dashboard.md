# LiteLLM Proxy Admin Dashboard

LiteLLM includes an administrative web interface for managing teams, virtual keys, models, and real-time usage metrics.

---

## Accessing the Dashboard

- **Direct HTTP URL**: [http://localhost:4000/ui](http://localhost:4000/ui)
- **HTTPS Reverse Proxy URL**: [https://localhost/admin/litellm/](https://localhost/admin/litellm/)
- **Master Authentication**: When prompted for an API key or password, enter the value of `LITELLM_MASTER_KEY` defined in your `.env` file.

---

## Key Dashboard Sections

### 1. Teams (`/ui/teams`)
This is where **Subscription Tiers** live:
- View all active tiers (`tier-basic`, `tier-premium`).
- Inspect the aggregated spend, number of requests, and assigned team members.
- Dynamically add or remove models from a tier's whitelist.
- Adjust monthly budget caps (`max_budget`) and rate limits (`tpm_limit`, `rpm_limit`) without restarting any containers.

### 2. Virtual Keys (`/ui/api-keys`)
Manage developer credentials:
- List all active virtual keys, their creation dates, expirations, and assigned users.
- Track individual user spend and remaining budget balance.
- Temporarily block or permanently delete compromised keys.
- Generate new keys bound to specific teams.

### 3. Models (`/ui/models`)
Examine the active model routing table:
- Review upstream backends (`api_base`), load-balancing weights, and model aliases (`basic-coder`, `premium-coder`, `premium-reasoning`).
- Verify model availability and test prompt completion directly from the UI playground.

### 4. Usage & Spend Analytics
- High-level charts showing daily token consumption, request volumes, and estimated costs per model and team.
- Identifies usage spikes and developers approaching their monthly tier quotas.
