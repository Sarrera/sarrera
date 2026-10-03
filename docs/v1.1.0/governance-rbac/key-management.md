# Virtual API Key Management

Sarrera issues **Virtual API Keys** to authenticate developers and client applications. Rather than giving developers direct access to underlying inference servers or shared master credentials, every developer receives their own isolated key bound to a subscription Tier.

---

## 1. Generating Keys via CLI Script

The fastest way to generate a key is using the provided [`scripts/issue-key.sh`](file:///Users/mario/repositorios/sarrera/scripts/issue-key.sh) utility.

### Syntax
```bash
./scripts/issue-key.sh <user_id> [tier] [duration] [department]
```

### Parameters
- `<user_id>`: Unique username or email identifier (e.g., `john_doe` or `dev_lead`).
- `[tier]`: Either `tier-basic` (default) or `tier-premium`.
- `[duration]`: Validity period before key expires (e.g., `30d`, `90d`, `365d`). Default: `90d`.
- `[department]`: Department tag for internal cost allocation (e.g., `Frontend`, `Backend`, `DevOps`). Default: `Engineering`.

### Example
```bash
./scripts/issue-key.sh sarah_connor tier-premium 180d "Core Architecture"
```

### Output
```text
==========================================================
 Generating API Key for User: sarah_connor in tier-premium
==========================================================

 Virtual API Key generated successfully:
 API Key: sk-litellm-abcdef1234567890...

----------------------------------------------------------
 Configuration for ~/.continue/config.json (VS Code):
----------------------------------------------------------
{
  "models": [
    {
      "title": "Sarrera (tier-premium)",
      "provider": "openai",
      "model": "premium-coder",
      "apiKey": "sk-litellm-abcdef1234567890...",
      "apiBase": "https://localhost/v1"
    }
  ]
}
----------------------------------------------------------
```

---

## 2. Generating Keys via LiteLLM Admin UI

1. Open the LiteLLM Dashboard at [http://localhost:4000/ui](http://localhost:4000/ui) (or [https://localhost/admin/litellm/](https://localhost/admin/litellm/)).
2. Authenticate using your `LITELLM_MASTER_KEY`.
3. In the left navigation bar, click on **"Virtual Keys"**.
4. Click the **"+ Create Key"** button in the top right.
5. In the modal:
   - **Key Alias**: e.g., `sarah_connor-key`.
   - **User ID**: e.g., `sarah_connor`.
   - **Team**: Select `tier-basic` or `tier-premium`. *(Selecting the team automatically inherits the tier's model permissions and budget limits)*.
   - **Duration / Expiration**: Set an optional expiration time.
6. Click **"Create"** and copy the generated token.

---

## 3. Revoking and Rotating Keys

### Revoke a Key via UI
1. Go to **"Virtual Keys"** in the LiteLLM dashboard.
2. Search for the key by alias or user ID.
3. Click the delete/trash icon or toggle the **Blocked** switch to disable the key immediately.

### Revoke a Key via REST API
```bash
curl -X POST "http://localhost:4000/key/delete" \
  -H "Authorization: Bearer sk-master-platform-key-change-me" \
  -H "Content-Type: application/json" \
  -d '{"keys": ["sk-litellm-key-to-delete"]}'
```
