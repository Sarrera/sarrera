# Cline, Roo Code & Cursor Integration

Beyond autocomplete and inline chat, Sarrera works out of the box with autonomous coding agents such as **Cline**, **Roo Code**, and **Cursor**.

---

## 1. Cline Configuration

Cline (formerly Claude Dev) supports custom OpenAI-compatible endpoints:

1. Open the **Cline** settings panel in VS Code.
2. Under **API Provider**, select **OpenAI Compatible**.
3. Fill in the parameters:
   - **Base URL**: `https://localhost/v1` (or `https://ai.company.local/v1`)
   - **API Key**: Your virtual key generated with `scripts/issue-key.sh` (e.g., `sk-litellm-...`).
   - **Model ID**:
     - For Basic Tier: `basic-coder`
     - For Premium Tier: `premium-coder` or `premium-reasoning`

---

## 2. Roo Code Configuration

Roo Code allows fine-grained role execution:

1. Open Roo Code settings.
2. Select **Provider**: `OpenAI-Compatible`.
3. Set **Base URL**: `https://localhost/v1`.
4. Enter your Sarrera API key.
5. In the model selector, specify `premium-coder` for architectural tasks and `basic-coder` for fast routine modifications.

---

## 3. Cursor IDE Configuration

1. Open Cursor Settings -> **Models**.
2. Under **OpenAI API Key**, toggle on **Override OpenAI Base URL**.
3. Set Base URL: `https://localhost/v1`.
4. Enter your Sarrera virtual API key.
5. In the model list, add `basic-coder` and `premium-coder`.

---

## 4. Rate Limiting Considerations for Autonomous Agents

Autonomous agents generate multi-turn loops (file reading, diff generation, lint checking, re-prompting) which can rapidly consume tokens:
- **Basic Tier keys** (`30k TPM`, `60 RPM`) may encounter `HTTP 429` rate limits during intensive multi-file refactoring runs.
- **Premium Tier keys** (`120k TPM`, `180 RPM`) are recommended when running autonomous agent loops.
