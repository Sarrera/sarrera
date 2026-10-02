#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Sarrera - Publish Launch Article to Medium.com via REST API
# ==============================================================================
# Usage:
#   MEDIUM_TOKEN="your_token" ./scripts/publish-medium.sh [--status draft|public]
#
# Get your Medium Integration Token at: https://medium.com/me/settings/security
# ==============================================================================

ENV_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
fi

ARTICLE_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/articles/medium-sarrera.md"
PUBLISH_STATUS="${1:-draft}"

# Normalize flag if user passes --status
if [ "$PUBLISH_STATUS" = "--status" ]; then
  PUBLISH_STATUS="${2:-draft}"
fi

echo "=========================================================="
echo " Sarrera - Medium Publisher"
echo " Target Status: ${PUBLISH_STATUS}"
echo "=========================================================="

if [ -z "${MEDIUM_TOKEN:-}" ]; then
  echo "❌ Error: MEDIUM_TOKEN is not defined."
  echo ""
  echo "How to get your Medium token:"
  echo "  1. Log into https://medium.com/me/settings/security"
  echo "  2. Scroll down to 'Integration tokens'"
  echo "  3. Generate a token with description 'Sarrera Publisher'"
  echo "  4. Run:"
  echo "     MEDIUM_TOKEN=\"<your-token>\" ./scripts/publish-medium.sh [draft|public]"
  echo ""
  echo "Or add MEDIUM_TOKEN=<your-token> into your .env file."
  exit 1
fi

if [ ! -f "$ARTICLE_FILE" ]; then
  echo "❌ Error: Article file not found at ${ARTICLE_FILE}"
  exit 1
fi

echo "🔍 [1/3] Authenticating with Medium API..."
USER_RESP=$(curl -s -w "\n%{http_code}" -X GET "https://api.medium.com/v1/me" \
  -H "Authorization: Bearer ${MEDIUM_TOKEN}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json")

HTTP_CODE=$(echo "$USER_RESP" | tail -n 1)
USER_BODY=$(echo "$USER_RESP" | sed '$d')

if [ "$HTTP_CODE" -ne 200 ]; then
  echo "❌ Authentication failed (HTTP ${HTTP_CODE}):"
  echo "$USER_BODY"
  exit 1
fi

USER_ID=$(python3 -c "import sys, json; print(json.loads('''$USER_BODY''')['data']['id'])")
USERNAME=$(python3 -c "import sys, json; print(json.loads('''$USER_BODY''')['data']['username'])")
USER_NAME=$(python3 -c "import sys, json; print(json.loads('''$USER_BODY''')['data']['name'])")

echo "✅ Authenticated as: ${USER_NAME} (@${USERNAME}) [ID: ${USER_ID}]"

echo "📄 [2/3] Preparing article content..."
TITLE="Building Sarrera: Self-Hosted Enterprise AI Inference Gateway with RBAC, Token Quotas & Telemetry"

# Prepare JSON payload safely via Python
PAYLOAD_FILE=$(mktemp)
python3 - <<EOF > "$PAYLOAD_FILE"
import json

with open("$ARTICLE_FILE", "r", encoding="utf-8") as f:
    content = f.read()

payload = {
    "title": "$TITLE",
    "contentFormat": "markdown",
    "content": content,
    "tags": ["Artificial Intelligence", "DevOps", "Docker", "Open Source", "Software Engineering"],
    "canonicalUrl": "https://github.com/Sarrera/sarrera",
    "publishStatus": "$PUBLISH_STATUS"
}

print(json.dumps(payload))
EOF

echo "🚀 [3/3] Uploading story to Medium (${PUBLISH_STATUS})..."
POST_RESP=$(curl -s -w "\n%{http_code}" -X POST "https://api.medium.com/v1/users/${USER_ID}/posts" \
  -H "Authorization: Bearer ${MEDIUM_TOKEN}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d @"$PAYLOAD_FILE")

rm -f "$PAYLOAD_FILE"

POST_CODE=$(echo "$POST_RESP" | tail -n 1)
POST_BODY=$(echo "$POST_RESP" | sed '$d')

if [ "$POST_CODE" -eq 201 ]; then
  POST_URL=$(python3 -c "import sys, json; print(json.loads('''$POST_BODY''')['data']['url'])")
  echo ""
  echo "=========================================================="
  echo "🎉 Success! Story created on Medium."
  echo "Status: ${PUBLISH_STATUS}"
  echo "URL:    ${POST_URL}"
  echo "=========================================================="
  if [ "$PUBLISH_STATUS" = "draft" ]; then
    echo "💡 Note: It was published as a DRAFT. Open the URL above to preview, adjust formatting if desired, and click 'Publish'."
  fi
else
  echo "❌ Error publishing story (HTTP ${POST_CODE}):"
  echo "$POST_BODY"
  exit 1
fi
