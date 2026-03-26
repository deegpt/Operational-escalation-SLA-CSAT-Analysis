# Tier 4 — Stored Procedures

> **File:** `Tier-4-Stored-Procedures.sql`
> **Concepts:** `CREATE PROCEDURE`, typed input parameters, `SET NOCOUNT ON`, `TOP (@n)`, `DROP IF EXISTS`
> **Tables:** `tickets`, `agents`, `customers`, `sla_logs`, `escalation_reasons`

---

## Purpose

A Stored Procedure is a **named, pre-compiled SQL block stored in the database** that accepts parameters at runtime.
This avoids repeating query logic in every application call and protects against SQL injection because user input is bound as typed parameters, never concatenated into SQL strings.

---

## Procedures

### SP1 — `sp_sla_breach_report`

**What it does:** Returns SLA breach rate, avg resolution time, avg CSAT, and the top breach reason — filtered by any date range and optionally a specific agent tier.

**Parameters:**

| Parameter | Type | Default | Description |
|---|---|---|---|
| `@p_start_date` | DATE | required | Start of reporting period |
| `@p_end_date` | DATE | required | End of reporting period |
| `@p_agent_tier` | VARCHAR(2) | NULL | L1 / L2 / L3 — NULL returns all |

**Sample Output** (`EXEC sp_sla_breach_report '2025-09-01', '2025-09-30', 'L1'`):

| issue_category | agent_tier | total_tickets | breaches | breach_rate_pct | avg_csat | top_breach_reason |
|---|---|---|---|---|---|---|
| PAYMENTS | L1 | 38 | 24 | 63.16 | 2.84 | High backlog |
| CARDS | L1 | 45 | 27 | 60.00 | 2.97 | Agent capacity |
| COMPLIANCE | L1 | 22 | 12 | 54.55 | 3.05 | Manual review delay |
| CREDIT | L1 | 31 | 14 | 45.16 | 3.19 | High backlog |

---

### SP2 — `sp_customer_escalation_history`

**What it does:** Returns the N most recent escalated tickets for a specific customer, fully enriched with escalation reason, SLA outcome, and customer profile.

**Parameters:**

| Parameter | Type | Default | Description |
|---|---|---|---|
| `@p_customer_id` | INT | required | Customer ID from customers table |
| `@p_top_n` | INT | 10 | Number of most recent escalations to return |

**Sample Output** (`EXEC sp_customer_escalation_history 1050, 3`):

| ticket_id | created_at | issue_category | csat_score | escalation_reason | sla_breached_flag | breach_reason |
|---|---|---|---|---|---|---|
| 9050 | 2025-09-05 02:00 | PAYMENTS | 2 | Agent capacity | 1 | High backlog |
| 9312 | 2025-09-18 14:00 | CARDS | 1 | Agent knowledge gap | 1 | Agent capacity |
| 9587 | 2025-10-04 09:00 | COMPLIANCE | 2 | Process failure | 0 | NULL |

---

## Execution Examples

```sql
-- September L1 agents only
EXEC sp_sla_breach_report '2025-09-01', '2025-09-30', 'L1';

-- Full Sep-Oct period, all tiers
EXEC sp_sla_breach_report '2025-09-01', '2025-10-31', NULL;

-- Last 5 escalations for customer 1001
EXEC sp_customer_escalation_history 1001, 5;

-- Last 10 escalations (default) for customer 1050
EXEC sp_customer_escalation_history 1050;
```

---

## Notes

- `SET NOCOUNT ON` suppresses the `(N rows affected)` message — important for clean application integration
- `TOP (@p_top_n)` uses a **variable** in TOP, which requires parentheses in SQL Server
- `DROP IF EXISTS` pattern ensures safe re-execution without errors
