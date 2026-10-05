# Load Balancing & Resilience Policies

Engineering teams have bursty usage patterns: dozens of developers might request code completions simultaneously. Sarrera implements intelligent load balancing to protect nodes from overload while maintaining fast response times.

---

## 1. Routing Strategy: `least-busy`

In [`config/litellm-config.yaml`](file:///Users/mario/repositorios/sarrera/config/litellm-config.yaml), the router is configured with:

```yaml
router_settings:
  routing_strategy: "least-busy"
  timeout: 45
  num_retries: 2
```

### How `least-busy` Works
- LiteLLM actively tracks the number of in-flight concurrent HTTP connections open to each backend node.
- When a new inference request arrives, LiteLLM routes it to the eligible server currently handling the fewest concurrent tasks.
- This prevents a slow 2000-token generation request on one server from queuing up subsequent 20-token inline autocomplete requests.

---

## 2. Weighted Balancing Across Heterogeneous Hardware

Not all servers possess equal computational power. For `basic-coder`, Sarrera balances traffic across mid-range GPUs and CPU clusters:

```yaml
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
```

- **Weight 8 (80% traffic distribution)** is directed to the dedicated GPU node (`RTX 3060/4060`), leveraging hardware tensor cores for sub-second generation.
- **Weight 2 (20% traffic distribution)** is directed to the CPU cluster, absorbing traffic spikes when the GPU node is near capacity.

---

## 3. Resilience, Timeouts & Automated Retries

### Request Timeout (`timeout: 45`)
If an inference server takes longer than 45 seconds to begin returning tokens (e.g., due to an out-of-memory stall or kernel lock), LiteLLM terminates the connection.

### Automated Retries (`num_retries: 2`)
When a request fails due to:
- A connection refusal (`ECONNREFUSED`),
- An HTTP `500 Internal Server Error`, or
- A timeout on the first node,

LiteLLM immediately fails over to the next available server in the weighted pool without returning an error to the developer. Only if all retries fail does the client receive an `HTTP 504 Gateway Timeout`.
