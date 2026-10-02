# SPEC-003: Governance, Tiers, and Audit Pipeline

## Status
Approved

## Tier Definitions (LiteLLM Teams)

User-level access control is enforced by provisioning virtual API keys bound to specific teams (`team_id`) in LiteLLM across 3 subscription tiers:

### 1. `tier-basic` (Basic Dev Subscription)
- **Permitted Models (`models`)**: `["basic-coder"]`
- **Monthly Budget (`max_budget`)**: 15.00 EUR
- **Budget Window (`budget_duration`)**: `30d`
- **Concurrency & Rate Limits**:
  - `rpm_limit`: 60 requests/minute
  - `tpm_limit`: 30,000 tokens/minute
- **Physical Compute Target**: GPU Standard (Weight 8) and CPU Cluster (Weight 2).

### 2. `tier-standard` (Standard Dev Subscription)
- **Permitted Models (`models`)**: `["basic-coder", "premium-coder"]`
- **Monthly Budget (`max_budget`)**: 50.00 EUR
- **Budget Window (`budget_duration`)**: `30d`
- **Concurrency & Rate Limits**:
  - `rpm_limit`: 120 requests/minute
  - `tpm_limit`: 60,000 tokens/minute
- **Physical Compute Target**: GPU Standard + GPU Premium (Standard code tasks without heavy reasoning models).

### 3. `tier-premium` (Premium AI Dev Subscription)
- **Permitted Models (`models`)**: `["premium-coder", "premium-reasoning", "basic-coder"]`
- **Monthly Budget (`max_budget`)**: 100.00 EUR
- **Budget Window (`budget_duration`)**: `30d`
- **Concurrency & Rate Limits**:
  - `rpm_limit`: 180 requests/minute
  - `tpm_limit`: 120,000 tokens/minute
- **Physical Compute Target**: GPU Premium node (A100 / RTX 4090) with priority fallback to Basic Tier hardware.

---

## Observability and Audit Pipeline (Langfuse)

1. **Credential Intake & Quota Validation**:
   - The developer's request hits `/v1/chat/completions` with an `Authorization: Bearer sk-...` header.
   - LiteLLM evaluates key validity, remaining monthly budget, and RPM/TPM limits against its PostgreSQL state.
2. **Routing & Model Authorization**:
   - LiteLLM checks whether the requested model is included in the team's `models` whitelist.
   - Routes the request to the optimal compute node according to the `least-busy` routing policy.
3. **Asynchronous Telemetry Callback**:
   - Immediately following the response to the client, LiteLLM dispatches a non-blocking callback to `http://langfuse:3000`:
     - `user_id` / `team_id`: Extracted from virtual key metadata.
     - `model`: Model requested and backend upstream node that executed inference.
     - `prompt` & `completion`: Full raw conversational payload for audit and compliance.
     - `tokens`: Exact token usage metrics (`prompt_tokens`, `completion_tokens`, `total_tokens`).
     - `latency`: Total request duration and TTFT (Time To First Token).
     - `cost`: Computed cost or internal chargeback to user department.
   - If the request fails or is blocked due to quota exhaustion, a `failure_callback` is recorded in Langfuse with the rejection reason.
