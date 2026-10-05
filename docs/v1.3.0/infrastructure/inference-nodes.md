# Inference Compute Nodes & Hardware Setup

Sarrera acts as an enterprise gateway in front of independent, distributed inference servers. These servers can be physical Linux workstations, on-premise rackmount servers, or dedicated cloud GPU instances running [Ollama](https://ollama.com/), [vLLM](https://github.com/vllm-project/vllm), or [TGI](https://github.com/huggingface/text-generation-inference).

---

## Node Topology

| Node Identifier | Physical Hardware | Engine | Hosted Models | Sarrera Alias | Port / Address |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Node 0: Local Integrated Node** | Host Machine (Apple Silicon / Linux / PC) | Docker Ollama (`ai-ollama-local`) | `deepseek-r1:14b`, `qwen2.5-coder:32b`, `qwen2.5-coder:7b`, `qwen2.5-coder:0.5b` | `local-reasoning`, `local-coder`, `basic-coder` | `ollama-local:11434` / `ollama.localhost` |
| **Node 1: GPU Premium** | Remote NVIDIA A100 (80GB) / RTX 4090 | Ollama / vLLM | `qwen2.5-coder:32b`, `deepseek-r1:14b` | `premium-coder`, `premium-reasoning` | `GPU_PREMIUM_HOST` |
| **Node 2: GPU Entry** | Remote NVIDIA RTX 3060 / 4060 (12GB) | Ollama / vLLM | `qwen2.5-coder:7b` | `basic-coder` | `GPU_ENTRY_HOST` |
| **Node 3: CPU Cluster** | Dual AMD EPYC / Intel Xeon (AVX-512) | Ollama CPU | `qwen2.5-coder:7b` (Q4_K_M) | `basic-coder` | `CPU_CLUSTER_HOST` |

---

## 1. Integrated Local Ollama Engine (`ai-ollama-local`)

Sarrera bundles a fully managed, containerized Ollama instance within `docker-compose.yml`:
- **Container**: `ai-ollama-local` (`ollama/ollama:latest`)
- **Volume Storage**: `ai-ollama-data` mounted at `/root/.ollama` to persist GGUF model weights across container restarts.
- **Perimeter Integration**: Routed by Caddy at `https://ollama.localhost/` and internally at `http://ollama-local:11434`.
- **Healthcheck**: Evaluates `ollama list || exit 1` every 10 seconds to ensure high availability.

### Managing Local Models via Docker CLI
To download and manage models directly in the integrated container:

```bash
# Pull models into the local container
docker compose exec ai-ollama-local ollama pull deepseek-r1:14b
docker compose exec ai-ollama-local ollama pull qwen2.5-coder:32b
docker compose exec ai-ollama-local ollama pull qwen2.5-coder:7b
docker compose exec ai-ollama-local ollama pull qwen2.5-coder:0.5b

# List downloaded weights and quantizations
docker compose exec ai-ollama-local ollama list

# Test execution directly in container
docker compose exec -it ai-ollama-local ollama run qwen2.5-coder:7b
```

### The Ollama Model Engine Inspector (Web UI)
Instead of relying on terminal commands, administrators and developers can navigate to:
👉 **`https://ollama.localhost/`** (or click **Ollama Model Inspector** in the Sarrera Admin Portal).

The inspector displays:
1. **Total Available Models**: Real-time count of pulled weights.
2. **Interactive Model Cards**:
   - Model name, family (`qwen2`, `deepseek`).
   - Parameter size (e.g. `14.8B`, `32.5B`, `7.6B`, `494M`).
   - Quantization format (e.g. `Q4_K_M`).
   - Exact storage footprint in GB/MB.
   - Quick-copy CLI commands (`ollama run <model>`).
3. **Endpoint Directory**: Direct links to `/api/tags`, `/api/generate`, `/api/chat`, and OpenAI compatibility layer.

---

## 2. Setting Up an External Remote Ollama Node

For dedicated remote GPU servers on your corporate LAN or cloud VPC:

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

### Exposing Ollama to the Local Network
By default, Ollama only listens on `127.0.0.1`. To allow Sarrera to connect, bind Ollama to `0.0.0.0`:

1. Edit the systemd service override:
   ```bash
   sudo systemctl edit ollama.service
   ```
2. Add the environment variable:
   ```ini
   [Service]
   Environment="OLLAMA_HOST=0.0.0.0:11434"
   ```
3. Reload and restart:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl restart ollama
   ```

### Pre-pulling Required Models
```bash
# On GPU Premium Node:
ollama pull qwen2.5-coder:32b
ollama pull deepseek-r1:14b

# On GPU Entry Node:
ollama pull qwen2.5-coder:7b

# On CPU Cluster Node:
ollama pull qwen2.5-coder:7b
```

---

## 3. Setting Up a vLLM Node (High-Throughput Production)

For larger teams requiring continuous batching and PagedAttention, vLLM offers higher concurrent throughput:

```bash
docker run --gpus all \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  -p 11434:8000 \
  --ipc=host \
  vllm/vllm-openai:latest \
  --model Qwen/Qwen2.5-Coder-32B-Instruct \
  --port 8000 \
  --max-model-len 16384 \
  --gpu-memory-utilization 0.95
```

---

## 4. Registering Nodes in Sarrera

Once your inference nodes are reachable over your internal network:

1. Update the host endpoints in your `.env` file on the Sarrera host:
   ```bash
   GPU_PREMIUM_HOST=http://192.168.1.50:11434
   GPU_ENTRY_HOST=http://192.168.1.51:11434
   CPU_CLUSTER_HOST=http://192.168.1.52:11434
   ```
2. Restart LiteLLM to load the new addresses:
   ```bash
   docker compose restart litellm
   ```
3. Run the smoke test to verify connectivity:
   ```bash
   ./scripts/smoke-test.sh
   ```

---

## 4.1 Registering Nodes from the Portal & Node Operations

> [!NOTE]
> **Available since v1.3.0.**

Nodes can also be registered directly from **Compute Nodes** in the governance portal (stored in LiteLLM, no restart needed). Each node card provides:

| Action | Effect |
| :--- | :--- |
| **Health ping** | Measures latency against the node's `api_base` |
| **Drain Traffic / Restore Traffic** | Blocks the node in LiteLLM so no new requests are routed to it (maintenance); restore returns it to the pool |
| **Terminal Access** | Copy-ready commands: `multipass shell <vm>`, `ssh ubuntu@<ip>`, `docker ps`, `ollama list` |
| **Operations & Reboot** | Copy-ready commands to restart the Ollama container, restart the node's Compose stack, or reboot the VM (`multipass restart <vm>`). Drain traffic first. |
| **Delete** | Removes the node from LiteLLM — and automatically from Prometheus scraping |

> [!TIP]
> Commands are displayed for copy/paste; the portal does not execute them remotely.

Live **CPU / RAM / disk / GPU** gauges are shown per node once the telemetry agents are installed. See [Hardware Telemetry with Prometheus](observability/prometheus-telemetry.md).

---

## 5. How Developers Select Models in VS Code

Developers have two integration paths depending on whether governance is required:

### Path A: Governed Enterprise Gateway (Recommended)
All requests pass through Caddy + LiteLLM, enforcing token budgets, rate limits, and Langfuse audit trails:
- **Endpoint**: `https://gateway.localhost/v1` (or `https://localhost/v1`)
- **API Key**: Virtual key assigned to developer (`sk-sarrera-...`)
- **Model Names**:
  - `basic-coder` (Routes to `qwen2.5-coder:7b`)
  - `premium-coder` (Routes to `qwen2.5-coder:32b`)
  - `premium-reasoning` (Routes to `deepseek-r1:14b`)

Example VS Code Continue configuration (`~/.continue/config.json`):
```json
{
  "models": [
    {
      "title": "Sarrera Premium Coder (32B)",
      "provider": "openai",
      "model": "premium-coder",
      "apiBase": "https://gateway.localhost/v1",
      "apiKey": "sk-sarrera-developer-key"
    },
    {
      "title": "Sarrera DeepSeek Reasoning (14B)",
      "provider": "openai",
      "model": "premium-reasoning",
      "apiBase": "https://gateway.localhost/v1",
      "apiKey": "sk-sarrera-developer-key"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Sarrera Fast Autocomplete",
    "provider": "openai",
    "model": "basic-coder",
    "apiBase": "https://gateway.localhost/v1",
    "apiKey": "sk-sarrera-developer-key"
  }
}
```

### Path B: Direct Local Engine (Offline / Standalone Development)
Direct connection to the local Ollama engine without quota limits:
- **Endpoint**: `https://ollama.localhost/v1` or `http://localhost:11434/v1`
- **API Key**: `ollama` (dummy key)
- **Model Names**: Exact model tag (e.g. `qwen2.5-coder:7b`, `deepseek-r1:14b`, `qwen2.5-coder:0.5b`).
