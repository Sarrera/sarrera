# REST API & cURL Usage

Because Sarrera provides complete OpenAI compatibility, you can consume models using standard `curl` commands, the official OpenAI Python/Node.js SDKs, or standard HTTP client libraries.

---

## 1. Listing Available Models

To list the models accessible with your virtual API key:

```bash
curl -k -s https://localhost/v1/models \
  -H "Authorization: Bearer sk-your-virtual-key" | jq .
```

---

## 2. Chat Completions (`curl`)

### Basic Tier Request (`basic-coder`)

```bash
curl -k -X POST https://localhost/v1/chat/completions \
  -H "Authorization: Bearer sk-basic-key-here" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "basic-coder",
    "messages": [
      {
        "role": "system",
        "content": "You are a concise programming assistant."
      },
      {
        "role": "user",
        "content": "Write a bash function to check if a port is open."
      }
    ],
    "temperature": 0.2
  }'
```

### Premium Tier Request (`premium-coder` or `premium-reasoning`)

```bash
curl -k -X POST https://localhost/v1/chat/completions \
  -H "Authorization: Bearer sk-premium-key-here" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "premium-reasoning",
    "messages": [
      {
        "role": "user",
        "content": "Analyze the time complexity of Dijkstra with a Fibonacci heap vs binary heap."
      }
    ],
    "stream": false
  }'
```

---

## 3. Streaming Responses

To receive streaming tokens in real time (Server-Sent Events / SSE):

```bash
curl -k -N -X POST https://localhost/v1/chat/completions \
  -H "Authorization: Bearer sk-your-key-here" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "basic-coder",
    "messages": [{"role": "user", "content": "Count from 1 to 5"}],
    "stream": true
  }'
```

---

## 4. Python SDK Example (`openai`)

You can use the official `openai` Python package by pointing `base_url` to your Sarrera gateway:

```python
from openai import OpenAI

# Initialize client pointing to Sarrera Gateway
client = OpenAI(
    base_url="https://localhost/v1",
    api_key="sk-your-virtual-key",
    # Set to False if using internal self-signed TLS certificates
    http_client=None 
)

response = client.chat.completions.create(
    model="basic-coder",
    messages=[
        {"role": "user", "content": "How do I reverse a string in Rust?"}
    ]
)

print(response.choices[0].message.content)
```
