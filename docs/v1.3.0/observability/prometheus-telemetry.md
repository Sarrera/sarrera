# Hardware Telemetry with Prometheus & Dynamic Node Discovery

> [!NOTE]
> **Available since v1.3.0.** Not present in v1.2.0 or earlier snapshots.

Sarrera collects live **CPU, RAM, disk and GPU** usage from every registered compute node and shows it in the **Compute Nodes** view of the governance portal. Scrape targets are **never hardcoded**: they are derived automatically from the nodes registered in LiteLLM.

---

## Architecture

```text
 ┌──────────────┐  /model/info   ┌──────────────────┐  HTTP SD   ┌──────────────────┐
 │ LiteLLM      │ ◄───────────── │ ai-discovery     │ ◄───────── │ ai-prometheus    │
 │ (registered  │                │ :8001            │  every 5s  │ :9090            │
 │  nodes)      │                └──────────────────┘            └────────┬─────────┘
 └──────────────┘                                                         │ scrape
                                         ┌────────────────────────────────┼───────────────┐
                                         ▼                                ▼               ▼
                                 node-exporter :9100              cadvisor :8080   dcgm-exporter :9400
                                 (CPU / RAM / disk)               (containers)     (NVIDIA GPU, optional)
```

1. An admin registers (or removes) a node in **Compute Nodes** → it is stored in LiteLLM.
2. `ai-discovery` reads `/model/info`, extracts the unique node hosts from each `api_base`, and serves them as [Prometheus HTTP SD](https://prometheus.io/docs/prometheus/latest/http_sd/) target lists.
3. Prometheus refreshes the target lists every 5 s, so nodes appear/disappear and IP changes are picked up with no config edits or restarts.

---

## Services

| Service | Container | Port | Portal access |
| :--- | :--- | :--- | :--- |
| Prometheus v2.51.0 | `ai-prometheus` | `9090` (bound to `127.0.0.1`) | `https://prometheus.localhost/` · `/admin/prometheus/*` |
| Node Discovery | `ai-discovery` | `8001` (internal only) | `/admin/discovery/*` |

Both are linked under **Platform Services** in the portal sidebar and dashboard (Prometheus Metrics, Prometheus Targets, Node Discovery).

### Discovery endpoints

| Endpoint | Returns |
| :--- | :--- |
| `/health` | `{"status": "ok"}` |
| `/targets/all` | Registered nodes (`host`, `node_name`, `api_base`) |
| `/targets/node-exporter` | `host:9100` targets |
| `/targets/cadvisor` | `host:8080` targets |
| `/targets/dcgm-exporter` | `host:9400` targets — **only nodes where port 9400 is reachable** (GPU nodes) |

Internal aliases (`gpu-premium-node`, `gpu-entry-node`, `cpu-cluster-node`, `ai-ollama-local`, `localhost`) are ignored.

### Scrape configuration ([`config/prometheus.yml`](https://github.com/Sarrera/sarrera/blob/main/config/prometheus.yml))

| Job | Source | Labels |
| :--- | :--- | :--- |
| `litellm` | static `litellm:4000/metrics/` | `role=inference-gateway` |
| `node-exporter` | HTTP SD | `role=compute-node`, `node_name`, `instance` |
| `cadvisor` | HTTP SD | `role=container-telemetry` |
| `dcgm-exporter` | HTTP SD | `role=gpu-telemetry` |

Retention: **15 days** (`prometheus_data` volume). Lifecycle API enabled (`--web.enable-lifecycle`).

---

## Installing the agents on a compute node

Run on each node (Docker required):

```bash
# CPU / RAM / disk
docker run -d --name node-exporter --restart unless-stopped \
  --net host --pid host -v /:/host:ro,rslave \
  prom/node-exporter:latest --path.rootfs=/host

# Container metrics
docker run -d --name cadvisor --restart unless-stopped -p 8080:8080 \
  -v /:/rootfs:ro -v /var/run:/var/run:ro -v /sys:/sys:ro \
  -v /var/lib/docker/:/var/lib/docker:ro gcr.io/cadvisor/cadvisor:latest

# NVIDIA GPU nodes only (requires NVIDIA Container Toolkit)
docker run -d --name dcgm-exporter --restart unless-stopped --gpus all -p 9400:9400 \
  nvcr.io/nvidia/k8s/dcgm-exporter:latest
```

Ports `9100`, `8080` and `9400` must be reachable from the Sarrera host.

---

## Metrics shown in Compute Nodes

| Gauge | PromQL |
| :--- | :--- |
| CPU % | `100 - avg by (instance)(rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100` |
| RAM % | `(MemTotal - MemAvailable) / MemTotal * 100` |
| Disk % (`/`) | `(size - avail) / size * 100` |
| GPU % | `DCGM_FI_DEV_GPU_UTIL` (fallbacks: `container_gpu_utilization`, `nvidia_smi_utilization_gpu_ratio`) |

**GPU vs CPU mode:** if a node exposes a GPU metric the card shows **`NVIDIA GPU (xx%)`**; otherwise it shows **`CPU Mode`** (accelerator column falls back to CPU).

---

## Troubleshooting

```bash
# Which nodes does discovery see?
curl -sk https://localhost/admin/discovery/targets/all

# Are targets UP in Prometheus?
open https://prometheus.localhost/targets

# Reload Prometheus after editing prometheus.yml
curl -X POST http://127.0.0.1:9090/-/reload
```

A node with no metrics usually means `node-exporter` is not running or port 9100 is firewalled.
