#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Sarrera - SemVer Version Bump & Documentation Snapshot Automation
# Part of the 'semver-versioning' Antigravity Skill (skill v1.1.0)
#
# Idempotent: re-run it whenever docs change before the release tag exists.
# Content docs (docs/**) and changelog text must be written BEFORE running it.
# ==============================================================================

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
DOCS_DIR="${REPO_DIR}/docs"
FRONTEND_DIR="${REPO_DIR}/frontend"

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <version> [description]"
  echo "Example: $0 1.3.0 'Prometheus telemetry and MFA'"
  exit 1
fi

RAW_VERSION="$1"
CLEAN_VERSION="${RAW_VERSION#v}"
TAG_VERSION="v${CLEAN_VERSION}"
DESCRIPTION="${2:-Release ${TAG_VERSION}}"

if ! [[ "${CLEAN_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "❌ Invalid SemVer: ${RAW_VERSION}"; exit 1
fi

if git -C "${REPO_DIR}" rev-parse -q --verify "refs/tags/${TAG_VERSION}" >/dev/null; then
  echo "❌ Tag ${TAG_VERSION} already exists: its snapshot is frozen. Choose a new version."; exit 1
fi

echo "=========================================================="
echo " Sarrera - Version ${TAG_VERSION}"
echo "=========================================================="

# 0. Changelog must already document this release
echo "🧾 [0/5] Checking changelog entries..."
for f in "${REPO_DIR}/CHANGELOG.md" "${DOCS_DIR}/operations/changelog.md"; do
  if ! grep -q "## \[${TAG_VERSION}\]" "$f"; then
    echo "❌ Missing '## [${TAG_VERSION}]' entry in ${f#${REPO_DIR}/}. Write release notes first."; exit 1
  fi
done
echo "  ✓ Changelog entries present"

# 1. Codebase manifests
echo "📝 [1/5] Updating code version constants..."
API_CONSTANTS="${FRONTEND_DIR}/lib/core/constants/api_constants.dart"
[ -f "${API_CONSTANTS}" ] && sed -i '' -E "s/static const String appVersion = 'v[^']+';/static const String appVersion = '${TAG_VERSION}';/" "${API_CONSTANTS}" && echo "  ✓ api_constants.dart → ${TAG_VERSION}"
PUBSPEC="${FRONTEND_DIR}/pubspec.yaml"
[ -f "${PUBSPEC}" ] && sed -i '' -E "s/^version: [0-9]+\.[0-9]+\.[0-9]+\+[0-9]+/version: ${CLEAN_VERSION}+1/" "${PUBSPEC}" && echo "  ✓ pubspec.yaml → ${CLEAN_VERSION}+1"

# 2 & 3. Navbar and index.html version selector (python for reliable multi-line edits)
echo "📑 [2-3/5] Updating _navbar.md and index.html version selector..."
python3 - "${DOCS_DIR}" "${TAG_VERSION}" <<'PY'
import re, sys, os
docs, tag = sys.argv[1], sys.argv[2]
ver = lambda s: tuple(int(x) for x in s.lstrip('v').split('.'))
snaps = sorted({d for d in os.listdir(docs) if re.fullmatch(r'v\d+\.\d+\.\d+', d)} | {tag}, key=ver, reverse=True)
older = [v for v in snaps if v != tag]

# navbar
nav = os.path.join(docs, '_navbar.md')
s = open(nav).read()
block = [f"* **Version: {tag}**", f"  * [{tag} (Current Release)](/ #/)"]
block += [f"  * [{v}](/{v}/ #/)" for v in older]
s = re.sub(r"\* \*\*Version: v[^\n]*\n(?:  \* \[v[^\n]*\n)*", "\n".join(block) + "\n", s, count=1)
open(nav, 'w').write(s)
print("  ✓ _navbar.md")

# index.html selector
idx = os.path.join(docs, 'index.html')
h = open(idx).read()
flag = lambda v: 'isV' + ''.join(v.lstrip('v').split('.')[:2])
m = re.search(r"( *)const isV\d+ = path\.includes\('/v[^']+'\);\n(?: *const isV\d+ = path\.includes\('/v[^']+'\);\n)* *const isLatest = [^\n]*\n", h)
opts = re.search(r"( *)<option value=\"#/\"[^\n]*\n(?: *<option value=\"v[^\n]*\n)*", h)
if m and opts:
    ind = m.group(1)
    flags = "".join(f"{ind}const {flag(v)} = path.includes('/{v}');\n" for v in reversed(older))
    flags += f"{ind}const isLatest = " + " && ".join(f"!{flag(v)}" for v in older) + ";\n"
    h = h[:m.start()] + flags + h[m.end():]
    opts = re.search(r"( *)<option value=\"#/\"[^\n]*\n(?: *<option value=\"v[^\n]*\n)*", h)
    oi = opts.group(1)
    lines = [f"{oi}<option value=\"#/\" \\${{isLatest ? 'selected' : ''}}>{tag} (Current Release)</option>"]
    for i, v in enumerate(older):
        label = "Previous Release" if i == 0 else "Legacy Snapshot"
        lines.append(f"{oi}<option value=\"{v}/#/\" \\${{{flag(v)} ? 'selected' : ''}}>{v} ({label})</option>")
    h = h[:opts.start()] + "\n".join(lines) + "\n" + h[opts.end():]
    open(idx, 'w').write(h)
    print("  ✓ index.html selector")
else:
    print("  ⚠️  Could not locate version selector in index.html — update manually")
PY

# 4. Workflow
echo "⚙️  [4/5] Verifying GitHub Pages deployment workflow..."
WORKFLOW="${REPO_DIR}/.github/workflows/deploy-docs.yml"
[ -f "${WORKFLOW}" ] && echo "  ✓ ${WORKFLOW#${REPO_DIR}/} publishes docs/ (snapshots included)"

# 5. Snapshot LAST (idempotent, removes stale files)
TARGET_DOCS_DIR="${DOCS_DIR}/${TAG_VERSION}"
echo "📁 [5/5] (Re)generating frozen documentation snapshot in docs/${TAG_VERSION}..."
mkdir -p "${TARGET_DOCS_DIR}"
rsync -a --delete --exclude '/v[0-9]*' --exclude '.nojekyll' "${DOCS_DIR}/" "${TARGET_DOCS_DIR}/"
touch "${TARGET_DOCS_DIR}/.nojekyll"
cp -f "${TARGET_DOCS_DIR}/index.md" "${TARGET_DOCS_DIR}/README.md" 2>/dev/null || true
echo "  ✓ $(find "${TARGET_DOCS_DIR}" -name '*.md' | wc -l | tr -d ' ') markdown files in snapshot"

echo "=========================================================="
echo "✅ ${TAG_VERSION} prepared."
echo "Next steps:"
echo "  1. ./scripts/build-portal.sh"
echo "  2. git commit -m 'chore(release): ${TAG_VERSION} - ${DESCRIPTION}'"
echo "  3. git tag ${TAG_VERSION}   (ask before pushing)"
echo "=========================================================="
