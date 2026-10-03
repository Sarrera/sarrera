# Troubleshooting Guide & Common Issues

Solutions for the most common errors encountered during local and production operations.

---

## 1. "Client sent an HTTP request to an HTTPS server"

### Cause
Occurs when an HTTP client (like a browser or curl) sends an unencrypted plain HTTP request directly to port `443` (e.g. typing `http://localhost:443`).

### Solution
- Connect using the `https://` protocol: `https://localhost/` or `https://localhost/v1/models`.
- Connect to port `80` with HTTP (`http://localhost`), where Caddy automatically redirects you to HTTPS (`443`).

---

## 2. "Model Not Allowed for Team" (HTTP 400 or HTTP 403)

### Cause
A developer using a `tier-basic` virtual API key sent a request requesting `premium-coder` or `premium-reasoning`.

### Solution
- This is intentional RBAC security enforcement.
- Verify the developer's assigned tier:
  ```bash
  curl -s -X GET 'http://localhost:4000/key/info?key=sk-developer-key' \
    -H "Authorization: Bearer sk-master-platform-key-change-me" | jq .
  ```
- If the developer legitimately requires premium models, upgrade their key or issue a new key bound to `tier-premium`:
  ```bash
  ./scripts/issue-key.sh developer_username tier-premium
  ```

---

## 3. "Budget Exceeded" (HTTP 400)

### Cause
The developer's team has exhausted its monthly budget allocation (`15.00 EUR` for basic or `100.00 EUR` for premium) within the current 30-day window.

### Solution
- Inspect team spend in the LiteLLM UI (`http://localhost:4000/ui/teams`).
- To increase the budget for `tier-basic`, make an update request:
  ```bash
  curl -X POST "http://localhost:4000/team/update" \
    -H "Authorization: Bearer sk-master-platform-key-change-me" \
    -H "Content-Type: application/json" \
    -d '{"team_id": "tier-basic", "max_budget": 25.0}'
  ```

---

## 4. Port Conflict on Startup (e.g. Ports 5432, 3000, or 8080 already in use)

### Cause
Another local service (such as a local PostgreSQL server, previously running containers, or an existing web app) is already listening on the requested port.

### Solution
Identify and stop the conflicting process:
```bash
# On macOS / Linux:
lsof -i :5432
lsof -i :3000
lsof -i :8080

# Or inspect running docker containers across your machine:
docker ps
```
Stop conflicting standalone containers before launching Sarrera:
```bash
docker stop <conflicting_container_name>
```

---

## 5. Gateway Timeout (HTTP 504)

### Cause
The upstream inference node (e.g. `GPU_PREMIUM_HOST` or `GPU_ENTRY_HOST`) took longer than 45 seconds to generate tokens or is unreachable over the network.

### Solution
1. Test connectivity to the upstream node from the Sarrera host:
   ```bash
   curl http://<GPU_HOST>:11434/api/version
   ```
2. Verify that the requested model is pre-downloaded on the node:
   ```bash
   curl http://<GPU_HOST>:11434/api/tags
   ```
3. Check container logs for LiteLLM:
   ```bash
   docker compose logs --tail=100 litellm
   ```

---

## 6. Self-Signed Certificate Warnings in VS Code

### Cause
Caddy uses internal self-signed TLS certificates by default in local development mode (`tls internal`).

### Solution
In VS Code:
1. Open Settings (`Cmd+,`).
2. Search for `proxyStrictSSL`.
3. Set `"http.proxyStrictSSL": false`.
