# Power BI Dashboard — Operational Escalation, SLA & CSAT Analysis

> **Project:** Operational Support Analytics · FinTech (Revolut-style)
> **Data source:** `opsSLA.db` (SQLite) · 5 tables · 1,200 tickets · Sep–Oct 2025
> **Tool:** Microsoft Power BI Desktop (free)
> **Author:** [@deegpt](https://github.com/deegpt)

---

## Dashboard Pages

| Page | Title | Purpose |
|---|---|---|
| 1 | Executive Overview | Top-level KPI cards + weekly trend lines |
| 2 | Escalation Deep Dive | Escalation by tier, reason, category, day |
| 3 | SLA Compliance | Breach rates, WoW change, breach reasons |
| 4 | CSAT & Agent Scorecard | CSAT distribution, agent health score matrix |
| 5 | High-Risk Triage | Daily churn-risk ticket table |

### Executive Overview
![Executive Overview](docs/executive_overview.png)

### Escalation Deep Dive
![Escalation Deep Dive](docs/escalation_deep_dive.png)

### SLA Compliance
![SLA Compliance](docs/sla_compliance.png)

### CSAT & Agent Scorecard
![Agent Scorecard](docs/csat_agent_scorecard.png)

### High-Risk Triage
![High-Risk Triage](docs/triage_risk.png)

---

## Build Order

```
Step 1 → Connect data (Power Query M)          PowerQuery_Connection.md
Step 2 → Build data model (relationships)      DataModel.md
Step 3 → Write all DAX measures                DAX_Measures.md
Step 4 → Build each dashboard page            Dashboard_Layout.md
```

---

## File Guide

| File | What it contains |
|---|---|
| `PowerQuery_Connection.md` | M code to load all 5 CSVs or SQLite into Power BI |
| `DataModel.md` | Star schema, relationship settings, filter directions |
| `DAX_Measures.md` | Every DAX measure — paste directly into Power BI |
| `Dashboard_Layout.md` | Page-by-page visual specs, fields, colours, slicers |
