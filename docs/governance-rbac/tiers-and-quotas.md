# Subscription Tiers & Token Quotas

To prevent runaway costs and protect physical GPU clusters from saturation, Sarrera establishes a multi-tier subscription model implemented via **LiteLLM Teams**.

---

## Tier Architecture

Each developer or service account is issued a virtual API key bound to a specific **Team**. The Team enforces:
1. **Model Whitelisting**: Strict list of abstract model names the key is allowed to call.
2. **Monthly Budget Cap**: Maximum financial or virtual spend permitted within a 30-day sliding window.
3. **Throughput Guardrails**: Maximum requests per minute (RPM) and tokens per minute (TPM).

---

## 3-Tier Enterprise Specifications

```text
┌───────────────────────────────────────────────────────────────────────────────┐
│                           SARRERA SUBSCRIPTION TIERS                          │
├───────────────────────┬───────────────────────────────┬───────────────────────┤
│      tier-basic       │         tier-standard         │     tier-premium      │
│   (Junior / Entry)    │        (Pro / Standard)       │     (Lead / Expert)   │
├───────────────────────┼───────────────────────────────┼───────────────────────┤
│ • basic-coder (7B)    │ • basic-coder (7B)            │ • basic-coder (7B)    │
│                       │ • premium-coder (32B)         │ • premium-coder (32B) │
│                       │                               │ • premium-reasoning   │
│                       │                               │   (DeepSeek-R1)       │
├───────────────────────┼───────────────────────────────┼───────────────────────┤
│ Budget: 15 EUR/month  │ Budget: 50 EUR/month          │ Budget: 100 EUR/month │
│ 60 RPM · 30k TPM      │ 120 RPM · 60k TPM             │ 180 RPM · 120k TPM    │
└───────────────────────┴───────────────────────────────┴───────────────────────┘
```

---

### 1. `tier-basic` (Basic Dev Subscription)
Designed for junior developers, routine code autocomplete, documentation lookups, and unit test generation:

| Parameter | Value | Description |
| :--- | :--- | :--- |
| **Team ID** | `tier-basic` | Internal identifier |
| **Team Alias** | *Basic Dev Subscription* | Display name in dashboard |
| **Permitted Models** | `["basic-coder"]` | Access restricted to 7B coding models |
| **Monthly Budget** | **15.00 EUR** / 30 days | Spend limit (`max_budget`) |
| **Budget Window** | `30d` | Sliding 30-day reset cycle |
| **RPM Limit** | **60 requests/minute** | Rate limit per user key |
| **TPM Limit** | **30,000 tokens/minute** | Throughput limit per user key |
| **Hardware Routing** | Standard GPU (weight 8) + CPU Cluster (weight 2) | Mid-range compute targets |

---

### 2. `tier-standard` (Standard Dev Subscription)
Designed for experienced software engineers, feature implementation, refactoring, and multi-turn chat:

| Parameter | Value | Description |
| :--- | :--- | :--- |
| **Team ID** | `tier-standard` | Internal identifier |
| **Team Alias** | *Standard Dev Subscription* | Display name in dashboard |
| **Permitted Models** | `["basic-coder", "premium-coder"]` | Access to 7B fast coder and 32B high-capacity coder |
| **Monthly Budget** | **50.00 EUR** / 30 days | Spend limit (`max_budget`) |
| **Budget Window** | `30d` | Sliding 30-day reset cycle |
| **RPM Limit** | **120 requests/minute** | Rate limit per user key |
| **TPM Limit** | **60,000 tokens/minute** | Throughput limit per user key |
| **Hardware Routing** | Standard GPU + Premium GPU | Mixed compute targets |

---

### 3. `tier-premium` (Premium AI Dev Subscription)
Designed for tech leads, software architects, complex multi-file refactoring, and deep reasoning tasks:

| Parameter | Value | Description |
| :--- | :--- | :--- |
| **Team ID** | `tier-premium` | Internal identifier |
| **Team Alias** | *Premium AI Dev Subscription* | Display name in dashboard |
| **Permitted Models** | `["premium-coder", "premium-reasoning", "basic-coder"]` | Full access to 32B models, DeepSeek-R1, and 7B |
| **Monthly Budget** | **100.00 EUR** / 30 days | Spend limit (`max_budget`) |
| **Budget Window** | `30d` | Sliding 30-day reset cycle |
| **RPM Limit** | **180 requests/minute** | High throughput limit |
| **TPM Limit** | **120,000 tokens/minute** | High token throughput |
| **Hardware Routing** | Premium GPU (NVIDIA A100 / RTX 4090) with fallback to Standard | High-end compute targets |

---

## Automatic Enforcement

When a developer sends a request with an `Authorization: Bearer sk-...` header:

1. **Model Validation**: LiteLLM checks if the requested model (e.g., `premium-reasoning`) is present in the key's team `models` whitelist.
   - If not allowed (e.g. a `tier-standard` key requesting `premium-reasoning`), LiteLLM immediately returns **`HTTP 403 Forbidden`** (`Model Not Allowed for Team tier-standard`).
   - The backend GPU cluster never receives or processes the unauthorized query.
2. **Quota Tracking**: LiteLLM checks the accumulated spend for the current 30-day window.
   - If accumulated spend exceeds `max_budget`, LiteLLM returns **`HTTP 400 Bad Request`** (`Budget Exceeded`).
3. **Rate Limiting**: If requests arrive faster than the defined RPM or TPM, LiteLLM returns **`HTTP 429 Too Many Requests`**.
