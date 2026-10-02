#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Sarrera - Initial Provisioning of 3 Subscription Tiers in LiteLLM
# ==============================================================================

# Load .env if present
ENV_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
fi

LITELLM_URL="${LITELLM_URL:-http://localhost:4000}"
MASTER_KEY="${LITELLM_MASTER_KEY:-sk-master-platform-key-change-me}"

echo "=========================================================="
echo " Registering 3 Service Tiers in Sarrera (LiteLLM Proxy) "
echo " Endpoint: ${LITELLM_URL}"
echo "=========================================================="

# 1. Basic Tier: 7B models on mid-range GPU / CPU cluster, 15 EUR/month budget
echo "[1/3] Registering Basic Tier (tier-basic)..."
curl -s -X POST "${LITELLM_URL}/team/new" \
  -H "Authorization: Bearer ${MASTER_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "team_id": "tier-basic",
    "team_alias": "Basic Dev Subscription",
    "models": ["basic-coder"],
    "max_budget": 15.0,
    "budget_duration": "30d",
    "tpm_limit": 30000,
    "rpm_limit": 60
  }' | (command -v jq >/dev/null && jq . || cat)

echo ""

# 2. Standard Tier: 7B + 32B models on GPU Entry/Standard, 50 EUR/month budget
echo "[2/3] Registering Standard Tier (tier-standard)..."
curl -s -X POST "${LITELLM_URL}/team/new" \
  -H "Authorization: Bearer ${MASTER_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "team_id": "tier-standard",
    "team_alias": "Standard Dev Subscription",
    "models": ["basic-coder", "premium-coder"],
    "max_budget": 50.0,
    "budget_duration": "30d",
    "tpm_limit": 60000,
    "rpm_limit": 120
  }' | (command -v jq >/dev/null && jq . || cat)

echo ""

# 3. Premium Tier: Access to 32B models, DeepSeek-R1 reasoning & basic tier, 100 EUR/month budget
echo "[3/3] Registering Premium Tier (tier-premium)..."
curl -s -X POST "${LITELLM_URL}/team/new" \
  -H "Authorization: Bearer ${MASTER_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "team_id": "tier-premium",
    "team_alias": "Premium AI Dev Subscription",
    "models": ["premium-coder", "premium-reasoning", "basic-coder"],
    "max_budget": 100.0,
    "budget_duration": "30d",
    "tpm_limit": 120000,
    "rpm_limit": 180
  }' | (command -v jq >/dev/null && jq . || cat)

echo ""
echo "----------------------------------------------------------"
echo " All 3 Service Tiers initialized successfully in LiteLLM."
echo "----------------------------------------------------------"
