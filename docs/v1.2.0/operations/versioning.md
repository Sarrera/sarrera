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
