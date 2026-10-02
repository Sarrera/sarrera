# Execution Context - Sarrera (Local AI Enterprise Platform)

## Objective
Deploy a private, Docker-based local AI inference platform that provides:
1. An OpenAI-compatible API endpoint for developer tools and IDE extensions such as VS Code (Continue, Cline, etc.).
2. An intelligent gateway and load balancer (LiteLLM) featuring token accounting, quotas, and dynamic routing across heterogeneous nodes (high-end GPU, mid-range GPU, CPU).
3. Full governance, observability, and audit logging of prompts and completions via Langfuse.
4. A web-based portal for chat, agent orchestration, and administration (Open WebUI) integrated with local auth and optional LDAP/Active Directory.
5. Granular Role-Based Access Control (RBAC/Teams) tied to service tiers and budget/billing boundaries.

## Technical Constraints
- Orchestrated exclusively using Docker Compose.
- Centralized PostgreSQL 16 database for LiteLLM and Langfuse (isolated databases/schemas).
- MinIO object storage for S3-compatible trace and audit event persistence (Langfuse backend).
- Strict Docker network segmentation (`ai-backend` isolated internally; only Caddy exposes ports 80/443).
- Native compatibility with local and remote inference backends served via Ollama, vLLM, or TGI.
