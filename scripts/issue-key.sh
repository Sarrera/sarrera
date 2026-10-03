#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Sarrera - Issue Virtual API Key by User and Tier
# ==============================================================================

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <user_id> [tier_or_group: tier-basic|tier-standard|tier-premium|group-<id>] [duration] [department]"
  echo "Example Solo:  $0 john_doe tier-standard 90d Backend"
  echo "Example Group: $0 carlos_acme group-acme-corp 90d \"Acme Engineering\""
  exit 1
fi

# Load .env if present
ENV_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
fi

USER_ID="$1"
TIER="${2:-tier-basic}"
DURATION="${3:-90d}"
DEPT="${4:-Engineering}"
LITELLM_URL="${LITELLM_URL:-http://localhost:4000}"
MASTER_KEY="${LITELLM_MASTER_KEY:-sk-master-platform-key-change-me}"
PUBLIC_URL="${PUBLIC_URL:-https://localhost/v1}"

echo "=========================================================="
echo " Generating API Key for User: ${USER_ID} in ${TIER}"
echo "=========================================================="

RESPONSE=$(curl -s -X POST "${LITELLM_URL}/key/generate" \
  -H "Authorization: Bearer ${MASTER_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"team_id\": \"${TIER}\",
    \"user_id\": \"${USER_ID}\",
    \"key_alias\": \"${USER_ID}-${TIER}-key\",
    \"duration\": \"${DURATION}\",
    \"metadata\": {
      \"department\": \"${DEPT}\",
      \"created_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
    }
  }")

KEY=$(echo "$RESPONSE" | (command -v jq >/dev/null && jq -r '.key' || grep -o '"key":"[^"]*"' | cut -d'"' -f4))

if [ -z "$KEY" ] || [ "$KEY" = "null" ]; then
  echo "Error generating virtual API key:"
  echo "$RESPONSE"
  exit 1
fi

# Determine default model to configure in IDE based on tier
case "$TIER" in
  tier-premium)
    DEFAULT_MODEL="premium-coder"
    ;;
  tier-standard)
    DEFAULT_MODEL="premium-coder"
    ;;
  *)
    DEFAULT_MODEL="basic-coder"
    ;;
esac

echo ""
echo " Virtual API Key generated successfully:"
echo " API Key: ${KEY}"
echo ""
echo "----------------------------------------------------------"
echo " Configuration for ~/.continue/config.json (VS Code):"
echo "----------------------------------------------------------"
cat << EOF
{
  "models": [
    {
      "title": "Sarrera (${TIER})",
      "provider": "openai",
      "model": "${DEFAULT_MODEL}",
      "apiKey": "${KEY}",
      "apiBase": "${PUBLIC_URL}"
    }
  ]
}
EOF
echo "----------------------------------------------------------"
