# VS Code Integration (Continue Extension)

[Continue](https://continue.dev/) is an open-source AI code assistant for Visual Studio Code and JetBrains IDEs. Sarrera integrates seamlessly with Continue by mimicking the standard OpenAI API.

---

## 1. Install Continue Extension

1. Open Visual Studio Code.
2. Go to the Extensions view (`Ctrl+Shift+X` or `Cmd+Shift+X`).
3. Search for **Continue** (by `Continue`) and click **Install**.

---

## 2. Configure Continue (`config.json`)

Open your Continue configuration file:
- On macOS/Linux: `~/.continue/config.json`
- On Windows: `%USERPROFILE%\.continue\config.json`
- Or click the gear icon in the bottom right of the Continue sidebar inside VS Code.

### Sample Configuration for Basic Tier

```json
{
  "$schema": "https://raw.githubusercontent.com/continuedev/continue/main/packages/config-yaml/schema.json",
  "models": [
    {
      "title": "Sarrera - Basic Coder (7B)",
      "provider": "openai",
      "model": "basic-coder",
      "apiKey": "sk-your-virtual-key-here",
      "apiBase": "https://localhost/v1"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Sarrera - Autocomplete",
    "provider": "openai",
    "model": "basic-coder",
    "apiKey": "sk-your-virtual-key-here",
    "apiBase": "https://localhost/v1"
  }
}
```

### Sample Configuration for Premium Tier

```json
{
  "$schema": "https://raw.githubusercontent.com/continuedev/continue/main/packages/config-yaml/schema.json",
  "models": [
    {
      "title": "Sarrera - Premium Coder (32B)",
      "provider": "openai",
      "model": "premium-coder",
      "apiKey": "sk-your-premium-key-here",
      "apiBase": "https://localhost/v1"
    },
    {
      "title": "Sarrera - Deep Reasoning (R1)",
      "provider": "openai",
      "model": "premium-reasoning",
      "apiKey": "sk-your-premium-key-here",
      "apiBase": "https://localhost/v1"
    },
    {
      "title": "Sarrera - Basic Coder (7B)",
      "provider": "openai",
      "model": "basic-coder",
      "apiKey": "sk-your-premium-key-here",
      "apiBase": "https://localhost/v1"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Sarrera - Autocomplete",
    "provider": "openai",
    "model": "basic-coder",
    "apiKey": "sk-your-premium-key-here",
    "apiBase": "https://localhost/v1"
  }
}
```

---

## 3. Self-Signed Certificate Setting

If connecting over HTTPS using Caddy's internal TLS certificate without installing the CA into your operating system trust store, instruct Continue / VS Code to permit local SSL certificates:

1. Open VS Code Settings (`Cmd+,` or `Ctrl+,`).
2. Search for `Http: Proxy Strict SSL`.
3. Uncheck **Strict SSL** (or set `"http.proxyStrictSSL": false` in your `settings.json`).

---

## 4. Model Switching in VS Code
 
1. Press `Cmd+L` (or `Ctrl+L`) to focus Continue Chat.
2. In the model selector dropdown at the bottom of the Continue panel, you will see all models listed in your `config.json` (e.g., **Sarrera - Basic Coder (7B)**, **Sarrera - Premium Coder (32B)**).
3. **Switch on the fly**:
   - Use **Basic Coder** for fast, cost-effective tab auto-completion and short syntax questions.
   - Switch to **Premium Coder** for deep refactoring, architectural reviews, or test suite generation.
4. **RBAC Guardrails**: If you configure a model not authorized by your assigned subscription Tier (e.g., attempting to run `premium-coder` on a `tier-basic` key), Sarrera immediately returns `HTTP 403 Forbidden` (`Model Not Allowed for Team tier-basic`). The request is terminated at the edge without reaching your GPU nodes.
5. As the model responds, check Langfuse at [http://localhost:3000](http://localhost:3000) (or via Caddy at `/admin/audit/`) to inspect live token metrics, execution traces, and prompt latency.
