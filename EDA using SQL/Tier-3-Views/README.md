# Tier 3 — Views

> **File:** `Tier-3-Views.sql`
> **Concepts:** `CREATE VIEW`, `DROP IF EXISTS`, composite scoring, multi-table JOINs encapsulated in reusable objects
> **Tables:** `tickets`, `agents`, `customers`, `sla_logs`, `escalation_reasons`

---

## Purpose

A SQL View is a **saved SELECT statement stored as a named database object**.
Instead of repeating complex JOINs in every query, a view exposes a clean, pre-joined result set.
Dashboards, BI tools, and downstream queries read the view as if it were a simple table.

---

## Views

### V1 — `vw_agent_performance_scorecard`

One row per agent. Aggregates all KPIs into a single scorecard including a **composite health score** (0–100):

```
health_score = (avg_csat / 5.0) × 40
             + (1 − esc_rate)   × 30
             + (1 − sla_breach) × 30
```

**Sample Output:**

| agent_id | agent_tier | total_tickets | avg_csat | esc_rate_pct | sla_breach_pct | agent_health_score |
|---|---|---|---|---|---|---|
| 202 | L3 | 14 | 3.79 | 14.3 | 21.4 | 77.4 |
| 212 | L3 | 11 | 3.64 | 18.2 | 27.3 | 72.1 |
| 283 | L1 | 16 | 3.25 | 25.0 | 37.5 | 61.3 |
| 257 | L1 | 12 | 2.91 | 50.0 | 58.3 | 43.2 |

---

### V2 — `vw_weekly_ops_summary`

One row per ISO week. Gives a Monday-morning management summary of all operational KPIs.

**Sample Output:**

| iso_week | ticket_volume | active_agents | esc_rate_pct | sla_breach_pct | avg_csat |
|---|---|---|---|---|---|
| 2025-W36 | 156 | 87 | 26.3 | 53.8 | 3.14 |
| 2025-W37 | 180 | 91 | 24.4 | 47.2 | 3.21 |
| 2025-W38 | 192 | 93 | 25.0 | 41.7 | 3.19 |
| 2025-W39 | 168 | 88 | 27.4 | 38.1 | 3.08 |

---

### V3 — `vw_high_risk_customer_tickets`

Filtered view: only tickets where `risk_flag = 1` AND `sla_breached_flag = 1`.
Ideal for a **daily churn-risk triage dashboard** or alerts pipeline.

**Sample Output:**

| ticket_id | customer_segment | risk_flag | sla_breached_flag | escalation_reason | breach_reason |
|---|---|---|---|---|---|
| 9050 | Premium | 1 | 1 | Agent capacity | High backlog |
| 9069 | Standard | 1 | 1 | NULL | High backlog |
| 9104 | Plus | 1 | 1 | Manual review delay | Agent capacity |
| 9136 | Premium | 1 | 1 | Agent capacity | Agent capacity |

---

## Usage

```sql
-- Full scorecard, best agents first
SELECT * FROM vw_agent_performance_scorecard
ORDER BY agent_health_score DESC;

-- Weekly trend for a Power BI line chart
SELECT iso_week, sla_breach_pct, avg_csat
FROM vw_weekly_ops_summary
ORDER BY iso_week;

-- Daily triage: how many high-risk customers hit SLA breach today?
SELECT customer_segment, COUNT(*) AS at_risk_count
FROM vw_high_risk_customer_tickets
WHERE CAST(created_at AS DATE) = CAST(GETDATE() AS DATE)
GROUP BY customer_segment;
```

> **Note:** SQL Server does not support `CREATE OR REPLACE VIEW`.
> The script uses `DROP IF EXISTS` + `CREATE VIEW` — safe to re-run at any time.
