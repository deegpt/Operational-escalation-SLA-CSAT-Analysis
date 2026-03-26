# 🎯 Escalation, SLA & CSAT Deep-Dive Analysis

> **Notebook:** `Escalation_SLA_CSAT_Analysis.ipynb`  
> **Database:** `opsSLA.db` (SQLite)  
> **Input table:** `tickets_esc_summary` (1,200 enriched records)  
> **Analysis period:** September 2025 – October 2025

This notebook performs a **targeted deep-dive** into the key operational metrics of a FinTech support environment — escalation rates, SLA compliance, CSAT scores, agent performance, and repeat contact behaviour. The goal is to translate raw support data into **evidence-based recommendations** for process and staffing improvements.

---

## 🎯 Objectives

- Identify the **top escalation reasons** and which issue categories drive them most
- Analyse **SLA breach patterns** by agent tier, region, and breach reason
- Understand **CSAT score distribution** and its relationship to escalation and SLA outcomes
- Benchmark **agent performance** across tiers (L1, L2, L3) and regions (EMEA, APAC)
- Investigate **repeat contact behaviour** by customer segment and risk profile
- Perform **statistical hypothesis testing** to validate observed differences
- Deliver **actionable process recommendations** backed by data

---

## 📂 Input Data

All analysis is performed on the `tickets_esc_summary` table — the enriched master view created during the EDA phase:

| Column Group | Key Fields |
|---|---|
| **Ticket** | `ticket_id`, `created_at`, `resolution_time_mins`, `resolution_time_hours` |
| **Issue** | `issue_category`, `escalation_flag`, `escalation_reason_id`, `reason_category` |
| **Customer** | `customer_id`, `customer_segment`, `tenure_months`, `risk_flag` |
| **Agent** | `agent_id`, `agent_tier`, `region`, `experience_months` |
| **SLA** | `sla_target_mins`, `sla_breached_flag`, `breach_reason`, `sla_risk_flag` |
| **Outcome** | `csat_score`, `repeat_contact_flag`, `severity_score`, `resolution_speed` |
| **Payment** | `payment_type`, `country` |
| **Temporal** | `created_date`, `created_week`, `created_month`, `created_hour`, `created_dow` |

---

## 📊 Analysis Sections

### 1. Escalation Analysis

**Top escalation reasons** (from 15 reason categories):
- Chargeback — Dispute raised for an unauthorized / incorrect transaction
- Plan Benefits — Paid plan benefits not applied or incorrectly processed
- Insurance — Delay or rejection in insurance claim processing
- Shops — Cashback or merchant shop rewards missing
- RevPoints — Incorrect RevPoints balance or redemption issue

**Key questions answered:**
- Which `issue_category` has the highest escalation rate?
- Does `payment_type` influence escalation likelihood?
- Is `customer_segment` (Standard / Metal / Premium) a predictor of escalation?
- How does `agent_tier` impact escalation outcomes?

---

### 2. SLA Breach Analysis

**SLA targets by severity:**
- Escalated / high-severity tickets: **360 minutes (6 hours)**
- Standard tickets: **240 minutes (4 hours)**
- Fast-track tickets: additional tier (varies)

**Breach reasons investigated:**
- `High backlog` — volume surge overwhelmed available capacity
- `Agent capacity` — insufficient agents available at time of assignment
- `None` — resolved within SLA target

**Key questions answered:**
- Which agent tier breaches SLA most frequently?
- Does region (EMEA vs APAC) affect SLA compliance rates?
- Are there day-of-week or time-of-day patterns in SLA breaches?
- What is the relationship between `severity_score` and SLA breach likelihood?

---

### 3. CSAT Score Analysis

**CSAT scale:** 1 (very dissatisfied) → 5 (very satisfied)

**Key questions answered:**
- How does CSAT score distribute across `issue_category`?
- Do escalated tickets consistently produce lower CSAT?
- Is there a statistically significant CSAT difference between SLA-compliant vs breached tickets?
- Which `customer_segment` shows the lowest average CSAT?
- Does `repeat_contact_flag` correlate with lower CSAT?

**Statistical tests used:**
- Independent samples **t-test** (`scipy.stats.ttest_ind`) — escalated vs non-escalated CSAT
- **Spearman correlation** — resolution time vs CSAT score

---

### 4. Agent Performance Benchmarking

| Metric | Comparison |
|---|---|
| Average resolution time | L1 vs L2 vs L3 |
| Escalation rate per agent | By tier and region |
| SLA compliance rate | By tier |
| Average CSAT score | By agent tier |
| Experience impact | `experience_months` vs resolution speed |

> Agents are anonymised by `agent_id` (201–300), covering **100 agents** across EMEA and APAC regions.

---

### 5. Repeat Contact Analysis

- Repeat contact (`repeat_contact_flag = 1`) indicates unresolved issues requiring a follow-up
- Analysed by `customer_segment`, `risk_flag`, and `issue_category`
- High-risk customers (`risk_flag = 1`) and lower-tenure customers show elevated repeat contact rates

---

### 6. Severity Score Distribution

The composite `severity_score` (0–3) combines:
- `escalation_flag` (+1)
- `sla_breached_flag` (+1)
- `repeat_contact_flag` (+1)

Tickets with `severity_score = 3` represent the **highest-priority cases** requiring immediate process intervention.

---

## 💡 Key Findings

| Finding | Detail |
|---|---|
| SLA breach rate | 33–54% across the period; declining trend over time |
| Escalation independence | Escalation rate is NOT correlated with ticket volume (p > 0.05) |
| Peak demand window | 9 AM – 2 PM; aligns with business-hour staffing needs |
| Agent tier impact | Higher tier agents (L2/L3) show faster resolution and higher CSAT |
| Chargeback & Plan Benefits | Top two escalation reason categories |
| High backlog & Agent capacity | Primary breach reasons — structural staffing gap |

---

## ⚡ Process Recommendations

1. **Increase L2 staffing** during historically high-volume weekdays to absorb overflow without escalation
2. **Introduce proactive escalation monitoring** during mid-week peaks (Tuesday–Thursday)
3. **Adjust weekend staffing** to reduce SLA breach risk on low-coverage days
4. **Use rolling weekly escalation rate** as an early-warning KPI in operational dashboards
5. **Target chargeback and plan-benefit training** for L1 agents to reduce avoidable escalations
6. **Align staffing rotas to 9 AM – 2 PM peak** for optimal SLA performance
7. **Prioritise high-risk / short-tenure customers** to reduce repeat contact rates and protect CSAT

---

## 📊 Libraries Used

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import sqlite3
import scipy.stats as stats
from scipy.stats import ttest_ind
import warnings
```

---

## 🔗 Previous Step

This notebook consumes the enriched `tickets_esc_summary` table produced by the [`Exploratory Data Analysis`](../Exploratory%20Data%20Analysis/) notebook.
