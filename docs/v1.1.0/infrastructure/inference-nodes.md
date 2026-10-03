# Inference Compute Nodes & Hardware Setup

Sarrera acts as an enterprise gateway in front of independent, distributed inference servers. These servers can be physical Linux workstations, on-premise rackmount servers, or dedicated cloud GPU instances running [Ollama](https://ollama.com/), [vLLM](https://github.com/vllm-project/vllm), or [TGI](https://github.com/huggingface/text-generation-inference).

---

## Node Topology

| Node Identifier | Physical Hardware | Engine | Hosted Models | Sarrera Alias |
| :--- | :--- | :--- | :--- | :--- |
| **Node 1: GPU Premium** | NVIDIA A100 (80GB) or RTX 4090 (24GB) | Ollama / vLLM | `qwen2.5-coder:32b`, `deepseek-r1:14b` | `premium-coder`, `premium-reasoning` |
| **Node 2: GPU Entry** | NVIDIA RTX 3060 / 4060 (12GB) | Ollama / vLLM | `qwen2.5-coder:7b` | `basic-coder` |
| **Node 3: CPU Cluster** | Dual AMD EPYC / Intel Xeon (AVX-512) | Ollama CPU | `qwen2.5-coder:7b` (Q4_K_M) | `basic-coder` |

---

## 1. Setting Up an Ollama Node

On your remote GPU server, install Ollama:

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

## 2. Setting Up a vLLM Node (High-Throughput Production)

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

## 3. Registering the Node in Sarrera

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
