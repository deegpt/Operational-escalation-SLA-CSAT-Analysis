# 🔍 Exploratory Data Analysis — Escalation, SLA & CSAT Drivers in FinTech Operations

> **Notebook:** `Exploratory-Data-Analysis.ipynb`  
> **Database:** `opsSLA.db` (SQLite)  
> **Records analysed:** 1,200 support tickets | Sep 2025 – Oct 2025

This notebook forms the **foundational layer** of the project. It establishes a clean, enriched dataset and uncovers the key temporal and operational patterns that drive escalations, SLA breaches, and customer satisfaction in a FinTech support environment.

---

## 🎯 Objectives

- Connect to the SQLite database and inspect all available tables
- Perform a full **data quality audit** (missing values, data types, cardinality)
- Engineer new features to enable richer downstream analysis
- Produce **temporal trend visualisations** across daily, weekly, and hourly dimensions
- Validate trends **statistically** using Spearman correlation and p-value testing
- Identify and flag **outliers** in resolution time
- Save the enriched master table back to the database

---

## 📂 Data Sources

All data is loaded via SQL queries from `opsSLA.db`:

| Table | Key Columns |
|---|---|
| `tickets` | `ticket_id`, `created_at`, `resolution_time_mins`, `issue_category`, `escalation_flag`, `payment_type`, `country`, `repeat_contact_flag`, `csat_score` |
| `agents` | `agent_id`, `agent_tier` (L1/L2/L3), `region` (EMEA/APAC), `experience_months` |
| `customers` | `customer_id`, `customer_segment`, `tenure_months`, `risk_flag` |
| `escalation_reasons` | `reason_category`, `description` |
| `sla_logs` | `sla_target_mins`, `actual_resolution_mins`, `sla_breached_flag`, `breach_reason` |

---

## 🧹 Data Quality Findings

| Column | Issue | Resolution |
|---|---|---|
| `escalation_reason_id` | 74.9% missing (expected — only escalated tickets have a reason) | Left as-is; used conditionally |
| `region` | 18% missing in `agents` table | Flagged; excluded from region-specific analyses |
| `resolved_at` | 13 rows missing | Investigated; excluded where needed |
| All other key columns | 0% missing | No action required |

---

## ⚙️ Feature Engineering

The following columns were added to create the enriched `tickets_esc_summary` table:

| Feature | Logic | Purpose |
|---|---|---|
| `resolution_time_hours` | `resolution_time_mins / 60` | Human-readable resolution duration |
| `sla_risk_flag` | Boolean from `sla_logs` | Identify at-risk tickets |
| `resolution_speed` | Fast (<2h) / Moderate (2–6h) / Slow (>6h) | Categorical speed label |
| `severity_score` | Sum of escalation + SLA breach + repeat contact flags | Composite risk score (0–3) |
| `created_date` | Date part of `created_at` | Daily aggregation |
| `created_week` | ISO week range string | Weekly aggregation |
| `created_month` | `YYYY-MM` format | Monthly aggregation |
| `created_hour` | Hour of day (0–23) | Intraday patterns |
| `created_dow` | Day of week (Monday–Sunday) | Day-of-week patterns |

---

## 📈 Analyses & Visualisations

### 1. Daily Ticket Volume Trend
- High day-to-day variability confirms **realistic fluctuation** (not flat synthetic data)
- Clear **volume spikes** in early September and mid-October — likely simulate system incidents or campaign-driven traffic
- Some days show very low volume (10–15 tickets), representing off-peak periods

> **Insight:** Ticket demand is not uniform. Sporadic surges suggest the need for **flexible, on-demand resource planning**.

---

### 2. Escalation Rate Over Time
- Escalation rate is tracked on a **weekly** and **daily** basis
- Weekly trends show moderate variability across the 8-week analysis window
- Spearman correlation between **ticket volume vs escalation rate** = **-0.58** (weekly) / **-0.03** (daily)
- **p-value = 0.13 / 0.81** → NOT statistically significant at α = 0.05

> **Conclusion:** Escalation rates are **independent of ticket volume**. Escalation is likely driven by *issue complexity or customer segment*, not workload.

---

### 3. Weekly SLA Breach Rate Trend
- SLA breach rate ranged between **33% and 54%** across weeks
- **Peak around mid-September (~54%)**, declining toward October (~33%)

> **Insight:** SLA performance improves over time, possibly due to process optimisation, better workload handling, or stabilisation after high-demand periods.

---

### 4. Hourly Ticket Creation Pattern
- Ticket creation follows a **typical business-hour distribution**
- Peak demand occurs around **midday (12 PM)**, with minimal activity during late-night hours (12 AM – 6 AM)

> **Operational Recommendation:** Support teams should be optimally staffed between **9 AM – 2 PM**. Reduced staffing during late-night hours improves efficiency and resource utilisation.

---

### 5. Outlier Detection
- IQR-based outlier detection applied to `resolution_time_mins`
- Extreme resolution-time outliers were **flagged and assessed** as process bottlenecks
- Outliers were **retained** (not dropped) to preserve analytical integrity and inform investigations

---

### 6. Pre- vs Post-Cleaning Validation
- Original `tickets` table: **13 columns**
- Enriched `tickets_esc_summary` table: **35 columns**
- All cleaning and enrichment steps validated for consistency before saving back to the database

> **Result:** Data preparation improved completeness and consistency while preserving analytical integrity.

---

## 📊 Libraries Used

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import sqlite3
from scipy.stats import spearmanr
```

---

## 🔗 Next Step

The enriched `tickets_esc_summary` table produced here is the **primary input** for the deep-dive analysis in the [`Ticket Escalation Summary`](../Ticket%20Escalation%20Summary/) notebook.
