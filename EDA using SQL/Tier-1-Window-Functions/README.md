# Tier 1 — Window Functions

> **File:** `Tier-1-Window-Functions.sql`
> **Concepts:** `RANK()`, `LAG()`, `SUM() OVER()`, `AVG() OVER (ROWS BETWEEN)`, `DATEPART(ISO_WEEK)`
> **Tables:** `tickets`, `agents`, `sla_logs`

---

## Purpose

Window functions let you perform calculations **across a set of rows that are related to the current row**, without collapsing them into a GROUP BY aggregate.
This file applies them to two operational monitoring questions that a support ops manager would track every Monday morning.

---

## Queries

### Q1 — Agent Ranking by Escalation Rate Within Tier (Week-over-Week)

**Business question:** *"Which agents within each tier consistently escalate the most, and how does their rank change week-over-week?"*

**Key techniques:**
- `RANK() OVER (PARTITION BY agent_tier, iso_week ORDER BY esc_rate DESC)` — ranks each agent within their tier for that week only
- `LAG(esc_rank_in_tier) OVER (PARTITION BY agent_id ORDER BY week_start_date)` — looks back one week for the same agent
- `SUM() OVER (ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)` — running cumulative ticket count

**Sample Output:**

| agent_tier | iso_week | agent_id | esc_rate_pct | esc_rank_in_tier | rank_change_wow | rank_trend |
|---|---|---|---|---|---|---|
| L1 | 2025-W36 | 257 | 50.00 | 1 | NULL | — First week |
| L1 | 2025-W36 | 224 | 44.44 | 2 | NULL | — First week |
| L1 | 2025-W37 | 257 | 55.56 | 1 | 0 | → No change |
| L1 | 2025-W37 | 220 | 50.00 | 2 | NULL | — First week |

---

### Q2 — SLA Breach Trend: Week-over-Week Change

**Business question:** *"By how much did the SLA breach rate improve or worsen each week compared to the previous week?"*

**Key techniques:**
- `LAG(breach_rate_pct) OVER (ORDER BY week_start_date)` — previous week's rate
- `AVG() OVER (ROWS BETWEEN 3 PRECEDING AND CURRENT ROW)` — 4-week rolling average to smooth weekly noise
- `DATEPART(ISO_WEEK, ...)` — true Monday–Sunday week boundaries

**Sample Output:**

| iso_week | breach_rate_pct | prev_week_breach_pct | wow_change_pct | rolling_4wk_avg_pct | trend_direction |
|---|---|---|---|---|---|
| 2025-W36 | 53.85 | NULL | NULL | 53.85 | — Baseline week |
| 2025-W37 | 47.22 | 53.85 | -6.63 | 50.54 | ▼ Improved |
| 2025-W38 | 41.67 | 47.22 | -5.55 | 47.58 | ▼ Improved |
| 2025-W39 | 38.10 | 41.67 | -3.57 | 45.21 | ▼ Improved |

---

## Key SQL Patterns Used

```sql
-- Partition by tier + week to rank agents within their own cohort
RANK() OVER (
    PARTITION BY agent_tier, iso_week
    ORDER BY total_escalations * 1.0 / NULLIF(total_tickets, 0) DESC
) AS esc_rank_in_tier

-- Look one week back for the same agent
LAG(esc_rank_in_tier) OVER (
    PARTITION BY agent_id
    ORDER BY week_start_date
) AS prev_week_rank

-- 4-week rolling average
AVG(breach_rate_pct) OVER (
    ORDER BY week_start_date
    ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
) AS rolling_4wk_avg_pct
```
