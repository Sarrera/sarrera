# Versioning Policy & Lifecycle

Sarrera follows a strict **Semantic Versioning (SemVer 2.0.0)** convention to ensure predictable upgrades, backward compatibility, and rock-solid platform stability for enterprise AI deployments.

---

## 1. SemVer Format: `MAJOR.MINOR.PATCH`

All platform artifacts (Docker images, Flutter Web Portal, CLI scripts, and documentation) share a synchronized release number in the format:

$$\Large \mathbf{v\,[MAJOR]\,.\,[MINOR]\,.\,[PATCH]}$$

```text
       ┌───────────── MAJOR: Platform Overhaul / Architecture Overhaul
       │  ┌────────── MINOR: Enhancements, Features, New Subsystems
       │  │  ┌─────── PATCH: Corrections, Bug Fixes, Security Patches
       ▼  ▼  ▼
      v1 . 1 . 0
```

### 1.1 `MAJOR` (First Number) — Total Platform Overhaul
Incremented **only** when there are fundamental platform redesigns, breaking API alterations, or incompatible architectural changes:
- Incompatible changes to perimeter proxy routing, TLS termination schemas, or ingress ports.
- Breaking database migrations in PostgreSQL (LiteLLM / Langfuse schema overhauls requiring manual data transformation).
- Deprecation of core enterprise dependencies or microservice interface contracts.

### 1.2 `MINOR` (Second Number) — Enhancements & New Capabilities
Incremented when new functionality, subsystems, or client integrations are added in a backwards-compatible manner:
- Adding the Flutter Web Governance Portal, Public Landing Page, and Developer Personal Workspace.
- Introducing new subscription tiers or dynamic compute backends (e.g. vLLM, TensorRT-LLM, AWS Bedrock).
- New client IDE configuration generators (VS Code Continue, Cursor, Cline, Roo Code).
- Automated administrator initialization via Docker Compose.

### 1.3 `PATCH` (Third Number) — Corrections & Maintenance
Incremented for backwards-compatible bug fixes, security patches, and reliability tweaks:
- Bug fixes in UI asset loading, icon font resolution, and HTTP cache headers.
- Hotfixes in GitHub Actions CI/CD workflows (e.g., GitHub Pages deployment repairs).
- Vulnerability remediation (CVE updates in underlying Alpine / Chainguard base containers).
- Refinements to rate limit calculation logic or cosmetic UI polish.

---

## 2. Synchronization Across Components

To prevent version skew between documentation, client configurations, and running services:

| Component | Manifest Location | Verification |
| :--- | :--- | :--- |
| **Web Portal** | `frontend/pubspec.yaml` & `ApiConstants.appVersion` | Rendered in sidebar footer & landing navbar pill |
| **Documentation** | `docs/index.html` & `docs/operations/changelog.md` | Published live on GitHub Pages |
| **Docker Compose** | `docker-compose.yml` image tags & `.env` | Tagged container images on releases |
| **Git Releases** | GitHub Tags (`git tag v1.1.0`) | Automated changelog and artifact builds |

---

## 3. Deprecation Policy

1. **Advance Notice**: Any feature or API route slated for removal will be marked as deprecated for at least one minor release cycle (`MINOR`) before being removed in the next `MAJOR` release.
2. **Telemetry Warnings**: Deprecated API routes emit audit warnings in Langfuse to alert administrators before enforcement.
3. **Documentation Runbooks**: Migration guides are published in the official GitHub Pages documentation under `Operations & Runbooks`.

---

## 4. Documentation Versioning Rules

Every release that changes behavior **must ship with its documentation in the same release**.

1. **Document first, snapshot last**: update the feature pages under `docs/` (architecture, configuration, governance, infrastructure, observability…), then create the `docs/vX.Y.Z/` snapshot. A snapshot taken before the docs are written is incomplete and must be regenerated.
2. **Version markers**: new or changed capabilities are tagged in the page with the release that introduced them:
   ```markdown
   > [!NOTE]
   > **Available since v1.3.0.**
   ```
   For inline items (table rows, list entries, compose services) use `*(since v1.3.0)*` or `*(v1.3.0+)*`.
3. **Breaking changes / deprecations**: mark with `> [!WARNING]` stating `Changed in vX.Y.Z` or `Deprecated in vX.Y.Z — removed in vX+1.0.0`, plus a migration note.
4. **Never edit frozen snapshots** (`docs/v1.0.0/`, `docs/v1.1.0/`, …) once a newer release exists, except to fix broken links. The current release snapshot may be regenerated until it is tagged.
5. **Navigation**: new pages must be added to `docs/_sidebar.md` and the Documentation Map in `docs/README.md`.
6. **Changelog** entries in `docs/operations/changelog.md` and `CHANGELOG.md` link to the relevant doc pages.

### Release checklist

| # | Step | Location |
| :--- | :--- | :--- |
| 1 | Classify change (PATCH / MINOR / MAJOR) | [SemVer rules](#_1-semver-format-majorminorpatch) |
| 2 | Update / create feature docs with version markers | `docs/**` |
| 3 | Sidebar & Documentation Map | `docs/_sidebar.md`, `docs/README.md` |
| 4 | Changelog | `CHANGELOG.md`, `docs/operations/changelog.md` |
| 5 | Version manifests | `api_constants.dart`, `pubspec.yaml` |
| 6 | Version selector & navbar | `docs/index.html`, `docs/_navbar.md` |
| 7 | Snapshot (last!) | `docs/vX.Y.Z/` |
| 8 | Rebuild portal, commit, tag | `./scripts/build-portal.sh`, `git tag vX.Y.Z` |
