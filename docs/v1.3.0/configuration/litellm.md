# LiteLLM Gateway Configuration

The core routing, rate limiting, and model abstraction of Sarrera is defined in [`config/litellm-config.yaml`](file:///Users/mario/repositorios/sarrera/config/litellm-config.yaml).

---

## Configuration File Breakdown

```yaml
model_list:
  # --- PREMIUM TIER (High-end GPUs: NVIDIA A100 / RTX 4090) ---
  - model_name: premium-coder
    litellm_params:
      model: ollama/qwen2.5-coder:32b
      api_base: os.environ/GPU_PREMIUM_HOST
      rpm: 180

  - model_name: premium-reasoning
    litellm_params:
      model: ollama/deepseek-r1:14b
      api_base: os.environ/GPU_PREMIUM_HOST
      rpm: 180

  # --- BASIC / STANDARD TIER (Weighted load balancing) ---
  - model_name: basic-coder
    litellm_params:
      model: ollama/qwen2.5-coder:7b
      api_base: os.environ/GPU_ENTRY_HOST
      weight: 8
      rpm: 60

  - model_name: basic-coder
    litellm_params:
      model: ollama/qwen2.5-coder:7b
      api_base: os.environ/CPU_CLUSTER_HOST
      weight: 2
      rpm: 20

router_settings:
  routing_strategy: "least-busy"
  timeout: 45
  num_retries: 2

general_settings:
  database_url: "os.environ/DATABASE_URL"
  enforce_user_param: false

litellm_settings:
  success_callback: ["langfuse"]
  failure_callback: ["langfuse"]
```

---

## Key Configuration Sections

### 1. Abstract Model Aliases (`model_name`)
Instead of having developers hardcode specific model strings and backend IPs in their IDE configurations, LiteLLM exposes **abstract aliases**:
- `basic-coder`: Bound to 7B coding models on entry GPUs or CPU clusters.
- `premium-coder`: Bound to 32B coding models on premium GPU nodes.
- `premium-reasoning`: Bound to DeepSeek-R1 reasoning models for complex architectural tasks.

### 2. Heterogeneous Load Balancing (`weight` & `routing_strategy`)
Notice that `basic-coder` appears twice in the `model_list`:
- Entry GPU node has `weight: 8`.
- CPU cluster node has `weight: 2`.

LiteLLM evaluates the `routing_strategy: "least-busy"`:
- Requests preferentially go to the GPU entry node.
- If the GPU node is occupied or reaches concurrency limits, requests are smoothly distributed to the CPU cluster.
- In case of backend failure, LiteLLM automatically retries (`num_retries: 2`) against an alternate node before returning an HTTP 504 error.

### 3. Environment Variable Interpolation
LiteLLM requires the `os.environ/VARIABLE_NAME` syntax for dynamic values:
```yaml
api_base: os.environ/GPU_PREMIUM_HOST
database_url: "os.environ/DATABASE_URL"
```
*(Do not use bash syntax `${VAR:-default}`, as LiteLLM parses `os.environ/` directly)*.

### 4. Telemetry Callbacks (`litellm_settings`)
By declaring:
```yaml
litellm_settings:
  success_callback: ["langfuse"]
  failure_callback: ["langfuse"]
```
LiteLLM dispatches a non-blocking asynchronous event to Langfuse upon completion of every inference request. This ensures auditing without introducing latency into developer requests.
