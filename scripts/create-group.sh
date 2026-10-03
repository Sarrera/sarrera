#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Sarrera - Provision B2B Corporate Client Group (Pooled Budget & Multi-Seat)
# ==============================================================================

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${REPO_DIR}/.env"

if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
fi

LITELLM_URL="${LITELLM_URL:-http://localhost:4000}"
MASTER_KEY="${LITELLM_MASTER_KEY:-sk-master-platform-key-change-me}"

GROUP_ID=""
GROUP_NAME=""
TIER="tier-standard"
BUDGET="500.0"
CONTACT_EMAIL=""
RPM="120"
TPM="60000"

usage() {
  cat << EOF
Usage: $0 [OPTIONS]

Provision a B2B corporate client group with pooled token quotas in Sarrera.

Options:
  -i, --id <slug>          Unique group identifier (e.g. acme-corp, auto-prefixed with group-)
  -n, --name <name>        Corporate client name (e.g. "Acme Corporation Enterprise")
  -t, --tier <tier>        Base subscription tier: tier-basic, tier-standard, tier-premium (Default: tier-standard)
  -b, --budget <amount>    Monthly pooled budget cap in EUR (Default: 500.0)
  -e, --email <email>      Billing or contact email
  -r, --rpm <rpm>          Rate limit requests per minute (Default: 120)
  -h, --help               Display this help message

Examples:
  $0 -i acme-corp -n "Acme Corporation" -t tier-standard -b 500 -e billing@acme.com
  $0 --id fintech-labs --name "FinTech Labs" --tier tier-premium --budget 1200
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--id) GROUP_ID="$2"; shift 2 ;;
    -n|--name) GROUP_NAME="$2"; shift 2 ;;
    -t|--tier) TIER="$2"; shift 2 ;;
    -b|--budget) BUDGET="$2"; shift 2 ;;
    -e|--email) CONTACT_EMAIL="$2"; shift 2 ;;
    -r|--rpm) RPM="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

if [ -z "$GROUP_ID" ]; then
  read -r -p "Enter Client Group ID (slug, e.g. acme-corp): " GROUP_ID
fi

if [ -z "$GROUP_NAME" ]; then
  read -r -p "Enter Client Company Name (e.g. Acme Corporation): " GROUP_NAME
fi

# Ensure group- prefix
if [[ ! "$GROUP_ID" =~ ^group- ]]; then
  GROUP_ID="group-${GROUP_ID}"
fi

# Set models according to tier
case "$TIER" in
  tier-premium)
    MODELS='["premium-coder", "premium-reasoning", "basic-coder"]'
    TPM="120000"
    [ "$RPM" == "120" ] && RPM="180"
    ;;
  tier-basic)
    MODELS='["basic-coder"]'
    TPM="30000"
    [ "$RPM" == "120" ] && RPM="60"
    ;;
  *)
    TIER="tier-standard"
    MODELS='["basic-coder", "premium-coder"]'
    TPM="60000"
    ;;
esac

echo "=========================================================="
echo " Sarrera - Provisioning Corporate Client Group"
echo "=========================================================="
echo " Group ID:       ${GROUP_ID}"
echo " Company Name:   ${GROUP_NAME}"
echo " Base Tier:      ${TIER}"
echo " Models:         ${MODELS}"
echo " Monthly Cap:    ${BUDGET} EUR"
echo " Throughput:     ${RPM} RPM / ${TPM} TPM"
echo " Contact Email:  ${CONTACT_EMAIL:-N/A}"
echo " Endpoint:       ${LITELLM_URL}"
echo "=========================================================="

PAYLOAD=$(cat <<EOF
{
  "team_id": "${GROUP_ID}",
  "team_alias": "${GROUP_NAME}",
  "models": ${MODELS},
  "max_budget": ${BUDGET},
  "budget_duration": "30d",
  "rpm_limit": ${RPM},
  "tpm_limit": ${TPM},
  "metadata": {
    "account_type": "group",
    "tier": "${TIER}",
    "client_name": "${GROUP_NAME}",
    "contact_email": "${CONTACT_EMAIL}"
  }
}
EOF
)

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${LITELLM_URL}/team/new" \
  -H "Authorization: Bearer ${MASTER_KEY}" \
  -H "Content-Type: application/json" \
  -d "${PAYLOAD}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
  echo "✅ Successfully provisioned client group '${GROUP_ID}'."
  echo ""
  echo "Enrolling members:"
  echo "  - In Web Portal: Navigate to 'Client Groups' -> Add Member"
  echo "  - Or onboard a user specifying --group ${GROUP_ID}"
  echo "----------------------------------------------------------"
else
  echo "❌ Error provisioning group (HTTP ${HTTP_CODE}):"
  echo "$BODY"
  exit 1
fi
