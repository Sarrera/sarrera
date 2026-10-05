import os
import json
import logging
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse
import urllib.request

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

LITELLM_HOST = os.environ.get("LITELLM_HOST", "http://litellm:4000")
LITELLM_KEY = os.environ.get("LITELLM_MASTER_KEY", "sk-master-platform-key-change-me")
PORT = int(os.environ.get("PORT", "8001"))

IGNORE_HOSTS = {
    "gpu-premium-node",
    "gpu-entry-node",
    "cpu-cluster-node",
    "ai-ollama-local",
    "localhost",
    "127.0.0.1",
    ""
}

def is_port_open(host, port, timeout=0.3):
    import socket
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True
    except Exception:
        return False

def get_registered_nodes():
    """
    Fetches all models registered in LiteLLM and extracts unique compute node hosts.
    Returns list of dicts: [{'host': '192.168.252.46', 'node_name': 'multipass-node-1', ...}]
    """
    url = f"{LITELLM_HOST.rstrip('/')}/model/info"
    req = urllib.request.Request(url)
    req.add_header("Authorization", f"Bearer {LITELLM_KEY}")
    
    try:
        with urllib.request.urlopen(req, timeout=4) as resp:
            if resp.status != 200:
                logging.error(f"LiteLLM returned status {resp.status}")
                return []
            body = resp.read().decode("utf-8")
            data = json.loads(body)
    except Exception as e:
        logging.error(f"Failed to fetch model info from {url}: {e}")
        return []

    nodes = []
    seen_hosts = set()

    for item in data.get("data", []):
        params = item.get("litellm_params", {})
        api_base = params.get("api_base", "")
        model_name = item.get("model_name", "node")
        
        parsed = urlparse(api_base)
        host = parsed.hostname or ""
        
        # If no scheme was passed, fallback to splitting by ':' or '/'
        if not host and api_base:
            host = api_base.replace("http://", "").replace("https://", "").split(":")[0].split("/")[0]

        if not host or host in IGNORE_HOSTS or host in seen_hosts:
            continue

        seen_hosts.add(host)
        nodes.append({
            "host": host,
            "node_name": model_name,
            "api_base": api_base
        })

    return nodes

class PrometheusDiscoveryHandler(BaseHTTPRequestHandler):
    def _send_json(self, status_code, data):
        payload = json.dumps(data).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_GET(self):
        path = self.path.split("?")[0].rstrip("/")

        if path == "/health" or path == "":
            self._send_json(200, {"status": "ok", "service": "sarrera-prometheus-discovery"})
            return

        if path == "/targets/node-exporter":
            nodes = get_registered_nodes()
            # Prometheus HTTP Service Discovery schema
            targets = []
            for n in nodes:
                targets.append({
                    "targets": [f"{n['host']}:9100"],
                    "labels": {
                        "node_name": n["node_name"],
                        "instance": n["host"],
                        "role": "compute-node"
                    }
                })
            self._send_json(200, targets)
            return

        if path == "/targets/cadvisor":
            nodes = get_registered_nodes()
            targets = []
            for n in nodes:
                targets.append({
                    "targets": [f"{n['host']}:8080"],
                    "labels": {
                        "node_name": n["node_name"],
                        "instance": n["host"],
                        "role": "container-telemetry"
                    }
                })
            self._send_json(200, targets)
            return

        if path == "/targets/dcgm-exporter":
            nodes = get_registered_nodes()
            targets = []
            for n in nodes:
                # Probe if port 9400 is actually active to avoid cluttering Prometheus on CPU-only nodes
                if is_port_open(n["host"], 9400):
                    targets.append({
                        "targets": [f"{n['host']}:9400"],
                        "labels": {
                            "node_name": n["node_name"],
                            "instance": n["host"],
                            "role": "gpu-telemetry"
                        }
                    })
            self._send_json(200, targets)
            return

        if path == "/targets/all":
            nodes = get_registered_nodes()
            self._send_json(200, {"count": len(nodes), "nodes": nodes})
            return

        self._send_json(404, {"error": "Not found", "available_paths": ["/targets/node-exporter", "/targets/cadvisor", "/targets/dcgm-exporter", "/health"]})

    def log_message(self, format, *args):
        # Suppress routine GET logging unless error to avoid noisy compose logs
        if "404" in str(args) or "500" in str(args):
            logging.warning("%s - %s", self.address_string(), format % args)

if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", PORT), PrometheusDiscoveryHandler)
    logging.info(f"Sarrera Prometheus Dynamic Discovery Service running on port {PORT}")
    server.serve_forever()
