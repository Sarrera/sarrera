# SPEC-002: Infrastructure and Inference Compute Nodes

## Status
Approved

## Compute Nodes (LiteLLM Upstreams)

The LiteLLM gateway centralizes outbound requests to distributed inference clusters (served via Ollama, vLLM, or TGI API over port 11434 or equivalent):

### Node 1: GPU Premium
- **Inference Host**: `gpu-premium-node:11434`
- **Compute Capacity**: NVIDIA A100 / RTX 4090
- **Hosted Models**:
  - `ollama/qwen2.5-coder:32b` (Alias: `premium-coder`)
  - `ollama/deepseek-r1:14b` (Alias: `premium-reasoning`)
- **Base Rate Limit**: 180 RPM

### Node 2: GPU Standard / Entry
- **Inference Host**: `gpu-entry-node:11434`
- **Compute Capacity**: NVIDIA RTX 3060 / RTX 4060
- **Hosted Models**:
  - `ollama/qwen2.5-coder:7b` (Alias: `basic-coder`)
- **Traffic Weight**: Weight 8
- **Base Rate Limit**: 60 RPM

### Node 3: CPU Cluster
- **Inference Host**: `cpu-cluster-node:11434`
- **Compute Capacity**: 32 vCPU AVX-512
- **Hosted Models**:
  - `ollama/qwen2.5-coder:7b` (Alias: `basic-coder`)
- **Traffic Weight**: Weight 2 (Spike smoothing and fallback)
- **Base Rate Limit**: 20 RPM

---

## Load Balancing and Resilience Policies

- **Routing Strategy (`routing_strategy`)**: `least-busy` with continuous latency probing and health checking.
- **Request Timeout (`timeout`)**: 45 seconds per inference request.
- **Retry Count (`num_retries`)**: 2 retries across alternate available nodes before returning an HTTP 504 Gateway Timeout.
- **Client Model Decoupling**: IDE clients (VS Code, Cursor, Cline) exclusively request abstract model identifiers (`basic-coder`, `premium-coder`, `premium-reasoning`), fully decoupling physical backends from end-user environments.
