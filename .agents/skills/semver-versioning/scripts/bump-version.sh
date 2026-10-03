#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Sarrera - SemVer Version Bump & Documentation Snapshot Automation
# Part of the 'semver-versioning' Antigravity Skill
# ==============================================================================

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
DOCS_DIR="${REPO_DIR}/docs"
FRONTEND_DIR="${REPO_DIR}/frontend"

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <version> [description]"
  echo "Example: $0 1.2.0 'Client groups and Caddy SSO'"
  exit 1
fi

RAW_VERSION="$1"
CLEAN_VERSION="${RAW_VERSION#v}" # remove leading 'v' if provided
TAG_VERSION="v${CLEAN_VERSION}"
DESCRIPTION="${2:-Release ${TAG_VERSION}}"

echo "=========================================================="
echo " Sarrera - Bumping Platform Version to ${TAG_VERSION}"
echo "=========================================================="

# 1. Create Documentation Version Snapshot
TARGET_DOCS_DIR="${DOCS_DIR}/${TAG_VERSION}"
echo "📁 [1/5] Creating frozen documentation snapshot in ${TARGET_DOCS_DIR}..."
mkdir -p "${TARGET_DOCS_DIR}"

rsync -av --exclude 'v*' --exclude '.nojekyll' "${DOCS_DIR}/" "${TARGET_DOCS_DIR}/"
touch "${TARGET_DOCS_DIR}/.nojekyll"
cp -f "${TARGET_DOCS_DIR}/index.md" "${TARGET_DOCS_DIR}/README.md" 2>/dev/null || true

# 2. Update Codebase Manifests
echo "📝 [2/5] Updating code version constants..."
API_CONSTANTS="${FRONTEND_DIR}/lib/core/constants/api_constants.dart"
if [ -f "${API_CONSTANTS}" ]; then
  sed -i '' -E "s/static const String appVersion = 'v[^']+';/static const String appVersion = '${TAG_VERSION}';/" "${API_CONSTANTS}"
  echo "  ✓ Updated ${API_CONSTANTS} to ${TAG_VERSION}"
fi

PUBSPEC="${FRONTEND_DIR}/pubspec.yaml"
if [ -f "${PUBSPEC}" ]; then
  sed -i '' -E "s/^version: [0-9]+\.[0-9]+\.[0-9]+\+[0-9]+/version: ${CLEAN_VERSION}+1/" "${PUBSPEC}"
  echo "  ✓ Updated ${PUBSPEC} to ${CLEAN_VERSION}+1"
fi

# 3. Update Docs Navigation & Navbar
echo "📑 [3/5] Updating documentation version navigation..."
NAVBAR="${DOCS_DIR}/_navbar.md"
if [ -f "${NAVBAR}" ]; then
  # Prepend the new release item
  sed -i '' -E "s/\* \*\*Version: v[^\*]+\*\*/\* \*\*Version: ${TAG_VERSION}\*\*/" "${NAVBAR}"
  if ! grep -q "${TAG_VERSION}" "${NAVBAR}"; then
    sed -i '' -E "s/(\* \*\*Version: ${TAG_VERSION}\*\*)/\1\n  \* [${TAG_VERSION} (Current Release)](\/ #\/)/" "${NAVBAR}"
  fi
fi

# 4. Verify Deploy Workflow
echo "⚙️  [4/5] Verifying GitHub Pages deployment workflow..."
WORKFLOW="${REPO_DIR}/.github/workflows/deploy-docs.yml"
if [ -f "${WORKFLOW}" ]; then
  if ! grep -q "${TAG_VERSION}" "${WORKFLOW}"; then
    echo "  Notice: Remember to verify ${WORKFLOW} includes ${TAG_VERSION} checks."
  fi
fi

# 5. Output Summary
echo "=========================================================="
echo "✅ Version bump to ${TAG_VERSION} completed successfully!"
echo "Next steps:"
echo "  1. Add release notes in docs/operations/changelog.md"
echo "  2. Run ./scripts/build-portal.sh to recompile frontend"
echo "  3. Git commit: git commit -m 'chore(release): ${TAG_VERSION} - ${DESCRIPTION}'"
echo "  4. Tag release: git tag ${TAG_VERSION}"
echo "=========================================================="
