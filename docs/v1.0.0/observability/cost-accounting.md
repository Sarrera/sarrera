# Department Cost Accounting & Chargeback

One of the primary challenges in enterprise AI adoption is cross-departmental cost visibility: knowing which business units, product squads, or engineering teams consume compute resources.

Sarrera provides built-in mechanisms for department chargeback and token cost accounting.

---

## Department Tagging Mechanism

When generating virtual API keys with [`scripts/issue-key.sh`](file:///Users/mario/repositorios/sarrera/scripts/issue-key.sh) or through the LiteLLM UI, metadata is attached to the key:

```bash
./scripts/issue-key.sh maria_garcia tier-premium 90d "Mobile-Apps"
```

The script injects:
```json
{
  "metadata": {
    "department": "Mobile-Apps",
    "created_at": "2026-10-02T12:00:00Z"
  }
}
```

Whenever LiteLLM dispatches telemetry to Langfuse, it attaches this `department` metadata tag to the trace.

---

## Cost Attribution Models

LiteLLM and Langfuse support two complementary cost tracking paradigms:

### 1. Internal Virtual Cost Modeling
Assigning an arbitrary internal credit value per million tokens (e.g. 1.00 EUR per 1M input tokens, 2.00 EUR per 1M output tokens).
- Teams receive a monthly budget allocation (e.g. 15.00 EUR for `tier-basic`, 100.00 EUR for `tier-premium`).
- As developers generate code, their remaining budget decreases proportionately.
- Managers can review burn rates and allocate higher quotas to priority projects.

### 2. Physical Hardware Amortization
For self-hosted hardware (NVIDIA A100 / RTX 4090 servers), raw electrical and hardware capital costs can be apportioned by:
$$\text{Cost per Department} = \frac{\text{Total Department Tokens}}{\text{Total Cluster Tokens}} \times \text{Monthly Operational Cost}$$

---

## Exporting Reports for Financial Auditing

### Export from LiteLLM
LiteLLM provides a `/global/spend/report` endpoint that returns aggregated spend per user, team, and tag in JSON format:
```bash
curl -X GET "http://localhost:4000/global/spend/report?start_date=2026-10-01&end_date=2026-10-31" \
  -H "Authorization: Bearer sk-master-platform-key-change-me"
```

### Export from Langfuse
Langfuse allows exporting trace summaries directly to CSV or querying the `traces` table in the PostgreSQL database:
```sql
SELECT 
  metadata->>'department' AS department,
  COUNT(*) AS total_requests,
  SUM((metadata->>'total_tokens')::numeric) AS tokens_consumed
FROM traces
GROUP BY metadata->>'department'
ORDER BY tokens_consumed DESC;
```
