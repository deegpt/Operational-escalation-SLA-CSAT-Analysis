# EDA using SQL — Operational Escalation, SLA & CSAT Analysis

> **Project:** Operational Support Analytics for a fintech platform (Revolut-style)
> **Dataset:** 1,200 tickets across 5 tables · Sep–Oct 2025
> **Database:** SQL Server (OpsSLA)
> **Author:** [@deegpt](https://github.com/deegpt)

---

## Project Overview

This folder contains all SQL analytical work for the **Operational Escalation, SLA & CSAT Analysis** project.
The queries are organised into 4 progressive tiers, each building on the previous to demonstrate increasing SQL complexity — from window functions through to stored procedures.

### Dataset Tables

| Table | Rows | Description |
|---|---|---|
| `tickets` | 1,200 | Core fact table — one row per support ticket |
| `sla_logs` | 1,200 | SLA target vs actual resolution per ticket |
| `agents` | 100 | Agent ID, tier (L1/L2/L3), region, experience |
| `customers` | 500 | Customer segment, tenure, risk flag |
| `escalation_reasons` | 15 | Lookup table — reason categories and descriptions |

### Business Questions Answered

| # | Question | Tier |
|---|---|---|
| Q1 | Which agents escalate most within their tier — week-over-week? | Tier 1 |
| Q2 | By how much did the SLA breach rate improve or worsen each week? | Tier 1 |
| Q3 | Which tickets fall in the bottom CSAT quartile per issue category? | Tier 2 |
| Q4 | What share of tickets at each severity level fail at each funnel stage? | Tier 2 |
| Q5 | Is FCR worse during peak hours, broken down by customer segment? | Tier 2 |

---

## Folder Structure

```
EDA-using-SQL/
├── README.md                                      ← You are here
├── Tier-1-Window-Functions/
│   ├── README.md
│   └── Tier-1-Window-Functions.sql
├── Tier-2-CTEs-and-Complex-Aggregations/
│   ├── README.md
│   └── Tier-2-CTEs-and-Complex-Aggregations.sql
├── Tier-3-Views/
│   ├── README.md
│   └── Tier-3-Views.sql
└── Tier-4-Stored-Procedures/
    ├── README.md
    └── Tier-4-Stored-Procedures.sql
```

---

## How to Run

1. Run `OpsSLA_SQLServer_Setup.sql` first to create and populate the database
2. Open any `.sql` file in **SSMS** or **Azure Data Studio**
3. Execute against the `OpsSLA` database
4. Tiers must be run in order if objects from earlier tiers are referenced

---

## SQL Concepts Demonstrated

`RANK()` · `LAG()` · `LEAD()` · `NTILE()` · `PERCENT_RANK()` · `DENSE_RANK()`
`SUM() OVER()` · `AVG() OVER (ROWS BETWEEN)` · `PARTITION BY` · `NULLIF()`
Multi-step CTEs · Conditional aggregation · `CASE` bucketing
`CREATE VIEW` · `CREATE PROCEDURE` · Parameterised queries · `DROP IF EXISTS`
