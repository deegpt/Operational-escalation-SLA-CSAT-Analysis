# Tier 2 — CTEs and Complex Aggregations

> **File:** `Tier-2-CTEs-and-Complex-Aggregations.sql`
> **Concepts:** Multi-step CTEs, `NTILE()`, `PERCENT_RANK()`, conditional `SUM(CASE WHEN)`, chained JOINs
> **Tables:** `tickets`, `agents`, `customers`, `sla_logs`, `escalation_reasons`

---

## Purpose

Common Table Expressions (CTEs) let you **break a complex query into named, readable steps** — like writing a function that builds on intermediate results.
This file chains 2–3 CTEs per query to answer multi-dimensional operational questions that a single SELECT could not cleanly express.

---

## Queries

### Q3 — CSAT Percentile Banding per Issue Category

**Business question:** *"Which tickets fall in the bottom 25th percentile of CSAT for each issue type — and what is their avg resolution time?"*

**Key techniques:**
- `NTILE(4) OVER (PARTITION BY issue_category ORDER BY csat_score)` — splits each category into four equal buckets
- `PERCENT_RANK()` — exact percentile position 0.0→1.0
- Window `SUM / AVG OVER (PARTITION BY issue_category)` — category-level aggregates alongside individual rows

**Sample Output:**

| issue_category | ticket_id | csat_score | csat_percent_rank | resolution_time_mins | escalation_reason | category_bottom_q_count |
|---|---|---|---|---|---|---|
| ACCOUNTS | 9036 | 1 | 0.0000 | 338 | Process failure | 58 |
| ACCOUNTS | 9117 | 1 | 0.0000 | 424 | NULL | 58 |
| CARDS | 9011 | 1 | 0.0000 | 249 | Agent knowledge gap | 61 |
| COMPLIANCE | 9010 | 1 | 0.0000 | 214 | Agent knowledge gap | 52 |

---

### Q4 — Escalation Funnel by Severity + Tier

**Business question:** *"What share of tickets at each severity level end up escalated, then SLA-breached, then repeat-contacted?"*

**Key techniques:**
- `CASE WHEN resolution_time_mins <= 120 THEN ...` — proxy severity bands since no severity column exists
- Three chained CTEs: tag severity → join SLA data → aggregate funnel stages
- `SUM(CASE WHEN escalation_flag=1 AND sla_breached_flag=1 THEN 1 ELSE 0 END)` — co-failure counting

**Sample Output:**

| severity_band | agent_tier | total_tickets | esc_rate_pct | sla_breach_pct | combined_failure_pct | avg_csat |
|---|---|---|---|---|---|---|
| LOW (<=2h) | L1 | 142 | 22.5 | 14.1 | 7.0 | 3.18 |
| LOW (<=2h) | L2 | 68 | 19.1 | 11.8 | 5.9 | 3.31 |
| MEDIUM (2-6h) | L1 | 198 | 27.3 | 38.4 | 15.2 | 2.97 |
| CRITICAL (>12h) | L1 | 24 | 41.7 | 75.0 | 37.5 | 2.41 |

---

### Q5 — First Contact Resolution (FCR) Rate by Hour Bucket

**Business question:** *"Is FCR worse during peak hours? Bucket the day into 4 shifts and compare."*

**Key techniques:**
- `DATEPART(HOUR, created_at)` bucketed into 4 named shifts
- `JOIN customers` to segment by plan tier (Standard / Premium / Plus / Metal / Ultra)
- `RANK() OVER (PARTITION BY customer_segment ORDER BY fcr_rate_pct DESC)` — best shift per segment

**Sample Output:**

| shift_bucket | customer_segment | fcr_rate_pct | avg_csat | fcr_rank_in_segment |
|---|---|---|---|---|
| 1_Night (00-05) | Metal | 82.4 | 3.41 | 1 |
| 1_Night (00-05) | Plus | 79.2 | 3.28 | 2 |
| 3_Afternoon (12-17) | Standard | 68.7 | 2.98 | 3 |
| 4_Evening (18-23) | Premium | 65.1 | 2.87 | 4 |
