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

---

### Executive Overview
![Executive Overview](https://raw.githubusercontent.com/deegpt/Operational-escalation-SLA-CSAT-Analysis/main/docs/executive_overview.png)

### Escalation Deep Dive
![Escalation Deep Dive](https://raw.githubusercontent.com/deegpt/Operational-escalation-SLA-CSAT-Analysis/main/docs/escalation_deep_dive.png)

### SLA Compliance
![SLA Compliance](https://raw.githubusercontent.com/deegpt/Operational-escalation-SLA-CSAT-Analysis/main/docs/sla_compliance.png)

### CSAT & Agent Scorecard
![Agent Scorecard](https://raw.githubusercontent.com/deegpt/Operational-escalation-SLA-CSAT-Analysis/main/docs/csat_agent_scorecard.png)

### High-Risk Triage
![High-Risk Triage](https://raw.githubusercontent.com/deegpt/Operational-escalation-SLA-CSAT-Analysis/main/docs/high_risk_triage.png)

---

## Build Order

```
Step 1 → Connect data (Power Query M)          Step-1-PowerQuery-Connection.md
Step 2 → Build data model (relationships)      Step-2-DataModel.md
Step 3 → Write all DAX measures                Step-3-DAX-Measures.md
Step 4 → Build each dashboard page            Step-4-Dashboard-Layout.md
```

---

## File Guide

| File | What it contains |
|---|---|
| `Step-1-PowerQuery-Connection.md` | M code to load all 5 CSVs + recreate all date feature columns |
| `Step-2-DataModel.md` | Star schema, relationship settings, filter directions |
| `Step-3-DAX-Measures.md` | Every DAX measure — paste directly into Power BI |
| `Step-4-Dashboard-Layout.md` | Page-by-page visual specs, fields, colours, slicers |
