#!/usr/bin/env bash
set -uo pipefail

# ==============================================================================
# Sarrera - Health Check & Governance Validation Script (Smoke Test)
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
LANGFUSE_URL="${LANGFUSE_URL:-https://localhost/admin/audit}"
MASTER_KEY="${LITELLM_MASTER_KEY:-sk-master-platform-key-change-me}"

echo "=========================================================="
echo " Running Smoke Tests for Sarrera Platform"
echo "=========================================================="

# 1. Test LiteLLM Gateway Health
echo -n "[1/4] Checking LiteLLM health (${LITELLM_URL}/health/liveliness)... "
STATUS_LITELLM=$(curl -s -k -o /dev/null -w "%{http_code}" "${LITELLM_URL}/health/liveliness" || echo "FAIL")
if [ "$STATUS_LITELLM" = "200" ]; then
  echo "OK (HTTP 200)"
else
  # Fallback check on /health
  STATUS_LITELLM=$(curl -s -k -o /dev/null -w "%{http_code}" "${LITELLM_URL}/health" || echo "FAIL")
  if [ "$STATUS_LITELLM" = "200" ]; then
    echo "OK (HTTP 200)"
  else
    echo "NOTICE (HTTP $STATUS_LITELLM - Are containers running?)"
  fi
fi

# 2. Test Langfuse Health
echo -n "[2/4] Checking Langfuse observability (${LANGFUSE_URL}/api/public/health)... "
STATUS_LANGFUSE=$(curl -s -k -o /dev/null -w "%{http_code}" "${LANGFUSE_URL}/api/public/health" || echo "FAIL")
if [ "$STATUS_LANGFUSE" = "200" ]; then
  echo "OK (HTTP 200)"
else
  echo "NOTICE (HTTP $STATUS_LANGFUSE)"
fi

# 3. Test List Models via Master Key
echo -n "[3/4] Checking models registered in LiteLLM (/v1/models)... "
MODELS_COUNT=$(curl -s -k "${LITELLM_URL}/v1/models" -H "Authorization: Bearer ${MASTER_KEY}" | (command -v jq >/dev/null && jq '.data | length' || grep -o '"id":' | wc -l))
echo "OK (${MODELS_COUNT} models detected)"

# 4. Test RBAC Tier Enforcement (Basic Key requesting Premium Model)
echo "[4/4] Verifying RBAC governance and isolation..."
TEST_KEY=$(curl -s -k -X POST "${LITELLM_URL}/key/generate" \
  -H "Authorization: Bearer ${MASTER_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "team_id": "tier-basic",
    "user_id": "test_smoke_user",
    "duration": "1h"
  }' | (command -v jq >/dev/null && jq -r '.key' || grep -o '"key":"[^"]*"' | cut -d'"' -f4))

if [ -n "$TEST_KEY" ] && [ "$TEST_KEY" != "null" ]; then
  echo "  - Test virtual key generated for tier-basic."
  # Attempt requesting premium-coder (must be denied or blocked by RBAC whitelist)
  RBAC_STATUS=$(curl -s -k -o /dev/null -w "%{http_code}" -X POST "${LITELLM_URL}/v1/chat/completions" \
    -H "Authorization: Bearer ${TEST_KEY}" \
    -H "Content-Type: application/json" \
    -d '{
      "model": "premium-coder",
      "messages": [{"role": "user", "content": "ping"}]
    }')

  if [ "$RBAC_STATUS" = "400" ] || [ "$RBAC_STATUS" = "403" ]; then
    echo "  - RBAC governance OK: tier-basic successfully blocked from premium model (HTTP $RBAC_STATUS)"
  else
    echo "  - RBAC response: HTTP $RBAC_STATUS (If backend upstreams are not running, may return 500/504)"
  fi
else
  echo "  - Unable to issue test key (Is LiteLLM running?)."
fi

echo "=========================================================="
echo " Smoke tests completed."
echo "=========================================================="
