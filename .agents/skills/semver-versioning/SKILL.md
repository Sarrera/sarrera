---
name: semver-versioning
description: Enforces Semantic Versioning (SemVer) and manages multi-version documentation snapshots across the codebase, Antigravity skills, and GitHub Pages. Activate on ANY functional change to the platform (new features, services, endpoints, UI capabilities, bug fixes), when updating versions, creating release tags, editing skills, or publishing versioned documentation.
---

# Semantic Versioning (SemVer) & Versioned Documentation Governance

> **Skill version: v1.1.0** — see [Skill Changelog](#5-skill-changelog).

This skill establishes the standard operational procedure for **Semantic Versioning (SemVer 2.0.0)** and **Versioned Documentation Management** across Sarrera, Antigravity skills, client SDKs, and platform documentation.

> [!IMPORTANT]
> **No feature without version + documentation.** Whenever code, architecture, configuration or skills are modified, the agent MUST, in the same task and without being asked:
> 1. Classify the change (PATCH / MINOR / MAJOR) against the **last git tag**.
> 2. Document it in the feature pages under `docs/` **with version markers**.
> 3. Bump versions, update changelogs, and (re)generate the docs snapshot **last**.
>
> Several features delivered in a row before tagging go into the **same pending release** — do not bump once per change; bump once and keep adding to that release until it is tagged.

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
  - Provisioning new non-breaking platform services or database tables (e.g. new containers in `docker-compose.yml`, new Platform Services links).
* **Skill Context**: Use when adding new reference markdown files (`references/`), helper scripts (`scripts/`), examples (`examples/`), or extending skill capabilities without breaking existing triggers.

### 🔴 Major Release (`X.0.0`)
* **When to apply**:
  - Drastic behavioral changes or breaking alterations in API contracts or architectures.
  - Incompatible changes to perimeter proxy routing, ingress port mappings, or TLS configurations.
  - Breaking database schema migrations requiring manual intervention or data transformation.
  - Removal or deprecation of previously supported endpoints, protocols, or core dependencies.
* **Skill Context**: Use when fundamentally restructuring skill activation parameters, breaking input/output contracts, or removing existing workflows.

### Determining the pending release
```bash
git describe --tags --abbrev=0          # last released tag, e.g. v1.2.0
grep appVersion frontend/lib/core/constants/api_constants.dart
```
- If `appVersion` == last tag → nothing pending: bump according to the matrix.
- If `appVersion` > last tag → a release is already pending: **add to it** (escalate MINOR→MAJOR only if a breaking change appears).

---

## 2. Versioned Documentation Protocol

### Step 0: Document the change (MANDATORY, before any snapshot)
For every functional change, update or create the relevant pages in `docs/`:

| Change type | Pages to touch |
| :--- | :--- |
| New container / service | `getting-started/architecture.md`, `configuration/docker-compose.md`, `configuration/caddy.md` (routes) |
| New UI capability / portal feature | Feature page in `governance-rbac/`, `infrastructure/` or `observability/` |
| New env variable | `configuration/environment-variables.md` |
| New script | `operations/scripts-reference.md` |
| New page | `docs/_sidebar.md` + Documentation Map & Key Features in `docs/README.md` (+ root `README.md` doc links) |

**Version markers are mandatory** for new/changed capabilities:
```markdown
> [!NOTE]
> **Available since vX.Y.Z.**
```
Inline (table rows, lists, compose services): `*(since vX.Y.Z)*` or `*(vX.Y.Z+)*`.
Breaking/deprecated: `> [!WARNING]` with `Changed in vX.Y.Z` / `Deprecated in vX.Y.Z` + migration note.

Docsify resolves links from the docs root (no `relativePath`), so link pages as `observability/page.md`, never `../observability/page.md`.

**Verify docs against the real code** (UI labels, metadata keys, endpoints, commands) before writing them.

### Step 1: Update Changelog
Document all changes in `docs/operations/changelog.md` and root `CHANGELOG.md` under:
- `### 🚀 Enhancements & New Features (MINOR)`
- `### 🐛 Bug Fixes & Improvements (PATCH)`
- `### ⚠️ Breaking Changes & Migrations (MAJOR)`

Each entry links to its doc page (`[docs](observability/page.md)` in `docs/`, `[docs](docs/observability/page.md)` in root).

### Step 2: Synchronize Codebase Manifests
- `frontend/lib/core/constants/api_constants.dart`: `static const String appVersion = 'vX.Y.Z';`
- `frontend/pubspec.yaml`: `version: X.Y.Z+<build>`
- `.github/workflows/deploy-docs.yml`: Verify snapshot directories are handled during packaging.

### Step 3: Update Version Dropdown & Navigation
1. `docs/_navbar.md`: new version as `(Current Release)`, previous versions as history:
   ```markdown
   * **Version: v1.3.0**
     * [v1.3.0 (Current Release)](/ #/)
     * [v1.2.0](/v1.2.0/ #/)
     * [v1.1.0](/v1.1.0/ #/)
     * [v1.0.0](/v1.0.0/ #/)
   ```
2. `docs/index.html`: add the `isVXY` flag and `<option>` for the new version in the version selector.

### Step 4: Create / Refresh Frozen Documentation Snapshot (LAST)
```bash
.agents/skills/semver-versioning/scripts/bump-version.sh X.Y.Z "Release summary"
```
The script mirrors `docs/` into `docs/vX.Y.Z/` with `rsync --delete` (idempotent). **Re-run it whenever docs change before the tag is created.** Never modify snapshots of already-superseded releases (except broken-link fixes).

### Step 5: Rebuild & Tag Release
1. `./scripts/build-portal.sh` and verify the new version string appears in `config/portal/main.dart.js`.
2. Commit and tag — **ask the user before pushing**:
   ```bash
   git add .
   git commit -m "chore(release): vX.Y.Z - <summary>"
   git tag "vX.Y.Z"
   git push && git push origin vX.Y.Z
   ```

---

## 3. Automation Helper Script

```bash
.agents/skills/semver-versioning/scripts/bump-version.sh <version> "Release summary"
```
Handles: changelog presence check, snapshot (re)generation, `.nojekyll`, manifests (`api_constants.dart`, `pubspec.yaml`), `_navbar.md` and `index.html` version selector. Content docs (Step 0) and changelog text (Step 1) remain the agent's responsibility.

---

## 4. Versioning the Skill Itself

Skills are versioned independently of the platform:
- The skill version lives in the `> **Skill version: vX.Y.Z**` line at the top of `SKILL.md`.
- Any edit to `SKILL.md`, `references/` or `scripts/` → classify with the matrix above, bump the skill version, and add an entry to the Skill Changelog below.
- Skill changes that alter the platform release workflow are also mentioned in the platform changelog of the pending release.

---

## 5. Skill Changelog

### v1.1.0 — 2026-10-05
- **MINOR**: Mandatory Step 0 "Document the change" with page mapping table and version markers (`Available since vX.Y.Z`).
- **MINOR**: "Pending release" rule — accumulate features into one unreleased version instead of bumping per change.
- **MINOR**: Snapshot is taken LAST and regenerated (`rsync --delete`) until the tag exists.
- **MINOR**: Self-versioning of the skill (this section).
- **PATCH**: `bump-version.sh` now updates `_navbar.md` and `index.html` reliably, checks changelog entries, and is idempotent.

### v1.0.0 — 2026-10-03
- Initial skill: SemVer matrix, docs snapshots, navbar/selector, changelog, manifests, bump script.
