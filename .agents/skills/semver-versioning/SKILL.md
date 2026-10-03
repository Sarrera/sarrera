---
name: semver-versioning
description: Enforces Semantic Versioning (SemVer) and manages multi-version documentation snapshots across the codebase, Antigravity skills, and GitHub Pages. Activate when updating versions, creating release tags, editing skills, or publishing versioned documentation.
---

# Semantic Versioning (SemVer) & Versioned Documentation Governance

This skill establishes the standard operational procedure for **Semantic Versioning (SemVer 2.0.0)** and **Versioned Documentation Management** across Sarrera, Antigravity skills, client SDKs, and platform documentation.

Whenever code, architecture, or skills are modified, follow this procedure to determine the appropriate version bump and synchronize all documentation versions.

---

## 1. SemVer Categorization Matrix

Version strings follow the standard format:
$$\mathbf{v\,[MAJOR]\,.\,[MINOR]\,.\,[PATCH]}$$

Always evaluate changes against the following three tiers:

### 🟢 Patch Release (`1.0.X`)
* **When to apply**:
  - Minor wording, phrasing, or typo corrections in documentation or skill instructions.
  - Non-breaking bug fixes, hotfixes, or stability adjustments.
  - Upgrading internal patch-level dependencies without API or behavior alterations.
  - Cosmetic UI tweaks and styling repairs that do not add new functional capabilities.
* **Skill Context**: Use for wording polishing, fixing typos in `SKILL.md`, or minor script bugfixes.

### 🟡 Minor Release (`1.X.0`)
* **When to apply**:
  - Adding new references, runbooks, guides, or compatible capabilities to the skill directory or docs.
  - Introducing new features, subdomains, endpoints, or client integrations in a backwards-compatible manner.
  - Adding new configuration options with safe, backwards-compatible defaults (e.g. SSO trusted headers, client groups).
  - Provisioning new non-breaking platform services or database tables.
* **Skill Context**: Use when adding new reference markdown files (`references/`), helper scripts (`scripts/`), examples (`examples/`), or extending skill capabilities without breaking existing triggers.

### 🔴 Major Release (`X.0.0`)
* **When to apply**:
  - Drastic behavioral changes or breaking alterations in API contracts or architectures.
  - Incompatible changes to perimeter proxy routing, ingress port mappings, or TLS configurations.
  - Breaking database schema migrations requiring manual intervention or data transformation.
  - Removal or deprecation of previously supported endpoints, protocols, or core dependencies.
* **Skill Context**: Use when fundamentally restructuring skill activation parameters, breaking input/output contracts, or removing existing workflows.

---

## 2. Versioned Documentation Protocol

Every version bump (**Minor** or **Major**, and significant **Patch** milestones) requires freezing a snapshot of the documentation to preserve historical runbooks for teams running legacy releases.

### Step 1: Create Frozen Documentation Snapshot
Mirror the current `docs/` tree into a dedicated version directory `docs/vX.Y.Z/`:
```bash
NEW_VERSION="v1.2.0"
mkdir -p "docs/${NEW_VERSION}"

# Copy documentation trees (excluding legacy version directories)
rsync -av --exclude 'v*' --exclude '.nojekyll' docs/ "docs/${NEW_VERSION}/"

# Ensure GitHub Pages Jekyll bypass and Docsify fallback
touch "docs/${NEW_VERSION}/.nojekyll"
cp -f "docs/${NEW_VERSION}/index.md" "docs/${NEW_VERSION}/README.md"
```

### Step 2: Update Version Dropdown & Navigation
1. Update `docs/_navbar.md` to list the new version as `(Current Release)` and move previous versions to legacy history:
   ```markdown
   * **Version: v1.2.0**
     * [v1.2.0 (Current Release)](/ #/)
     * [v1.1.0](/v1.1.0/ #/)
     * [v1.0.0](/v1.0.0/ #/)
     * [Versioning Policy](operations/versioning.md)
     * [Changelog & History](operations/changelog.md)
   ```
2. Update the version selector in `docs/index.html` to include the new version option in the interactive sidebar selector.

### Step 3: Update Changelog
Document all changes in `docs/operations/changelog.md` and root `CHANGELOG.md` under:
- `### 🚀 Enhancements & New Features (MINOR)`
- `### 🐛 Bug Fixes & Improvements (PATCH)`
- `### ⚠️ Breaking Changes & Migrations (MAJOR)`

### Step 4: Synchronize Codebase Manifests
Update the version across all platform manifests:
- `frontend/lib/core/constants/api_constants.dart`: `static const String appVersion = 'vX.Y.Z';`
- `frontend/pubspec.yaml`: `version: X.Y.Z+<build>`
- `.github/workflows/deploy-docs.yml`: Verify snapshot directories are handled during packaging.

### Step 5: Rebuild & Tag Release
1. Recompile web assets:
   ```bash
   ./scripts/build-portal.sh
   ```
2. Commit and create Git tag:
   ```bash
   git add .
   git commit -m "chore(release): bump version to vX.Y.Z"
   git tag "vX.Y.Z"
   ```

---

## 3. Automation Helper Script

The skill provides an automated helper script at `scripts/bump-version.sh`:
```bash
.agents/skills/semver-versioning/scripts/bump-version.sh <new_version> <patch|minor|major> "Release summary"
```
This script handles snapshot duplication, navbar updating, `.nojekyll` verification, and manifest updates automatically.
