# Prerequisites & Hardware Requirements

Before deploying Sarrera, ensure your environment meets the minimum hardware, software, and networking specifications.

---

## 💻 Hardware Requirements

### Control Plane (Sarrera Stack Host)
The Sarrera stack itself (LiteLLM, Langfuse, Caddy, Open WebUI, PostgreSQL, MinIO) is lightweight:

| Component | Minimum Specification | Recommended Production |
| :--- | :--- | :--- |
| **CPU** | 4 Cores (x86_64 or ARM64 / Apple Silicon) | 8 Cores |
| **RAM** | 8 GB RAM | 16 GB RAM |
| **Disk Storage** | 30 GB SSD | 100+ GB NVMe SSD |
| **Network** | 1 Gbps NIC | 10 Gbps NIC |

### Inference Nodes (GPU / CPU Compute Hosts)
Upstream servers running inference run independently or on the same host if local:

| Tier | Target Workload | Minimum GPU / VRAM | Hosted Models |
| :--- | :--- | :--- | :--- |
| **Premium Tier** | Complex architecture, refactoring, deep reasoning | NVIDIA A100 (40GB/80GB) or RTX 4090 (24GB) | `qwen2.5-coder:32b`, `deepseek-r1:14b` |
| **Standard Tier** | Daily code autocomplete, docstrings, unit tests | NVIDIA RTX 3060 / 4060 (8GB - 12GB) | `qwen2.5-coder:7b` |
| **CPU Cluster** | Peak spike absorbing, fallback | Multi-core x86 (AVX-512 supported) | `qwen2.5-coder:7b` (quantized Q4_K_M) |

---

## 🛠️ Software Requirements

1. **Docker Engine**: Version 24.0 or higher.
2. **Docker Compose**: Plugin v2.20 or higher (`docker compose` CLI).
3. **Curl & JQ**: Command-line utilities for executing provisioning and smoke-test scripts (`curl`, `jq`).
4. **Git**: For version control and deployment tracking.
5. **NVIDIA Container Toolkit** *(Only if running inference containers locally on NVIDIA GPUs)*:
   ```bash
   # Verify NVIDIA drivers on Linux:
   nvidia-smi
   ```

---

## 🌐 Network Ports & Connectivity

The following ports are utilized by default:

| Port | Service | Scope | Protocol | Description |
| :--- | :--- | :--- | :--- | :--- |
| **80** | Caddy | Public / Corporate LAN | TCP / HTTP | Auto-redirects to HTTPS (443) |
| **443** | Caddy | Public / Corporate LAN | TCP / HTTPS | Secure TLS entrypoint for all endpoints |
| **4000** | LiteLLM | Localhost / Internal | TCP / HTTP | Direct API Gateway & Admin UI |
| **3000** | Langfuse | Localhost / Internal | TCP / HTTP | Direct Observability Web UI |
| **8080** | Open WebUI | Localhost / Internal | TCP / HTTP | Direct Chat Portal UI |
| **9001** | MinIO | Localhost / Internal | TCP / HTTP | MinIO Web Console |
| **5432** | PostgreSQL | Internal Docker Network | TCP | Database backend |
| **9000** | MinIO | Internal Docker Network | TCP | S3 API endpoint for Langfuse |
| **11434** | Ollama / vLLM | Internal or Remote LAN | TCP / HTTP | Upstream LLM inference engines |
