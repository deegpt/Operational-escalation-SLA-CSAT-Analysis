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

---

### 1. Daily Ticket Volume Trend

**Research Question:** How does ticket volume fluctuate day-to-day, and are there detectable surge patterns?

```python
import plotly.graph_objects as go
import pandas as pd

daily = tickets_enriched.groupby(tickets_enriched['created_at'].dt.date).size().reset_index(name='tickets')
daily['created_date'] = pd.to_datetime(daily['created_at'])
rolling = daily['tickets'].rolling(7, min_periods=1).mean()

fig = go.Figure()
fig.add_trace(go.Scatter(
    x=daily['created_date'], y=daily['tickets'],
    mode='lines', name='Daily Tickets',
    line=dict(color='#4C9BE8', width=1.5),
    fill='tozeroy', fillcolor='rgba(76,155,232,0.12)'
))
fig.add_trace(go.Scatter(
    x=daily['created_date'], y=rolling,
    mode='lines', name='7-day Rolling Avg',
    line=dict(color='#E8A14C', width=2.5, dash='dot')
))
fig.update_layout(title='Daily Ticket Volume (Sep–Oct 2025)')
fig.update_xaxes(title_text='Date', tickformat='%b %d')
fig.update_yaxes(title_text='Tickets/Day')
fig.show()
```

- High day-to-day variability confirms **realistic fluctuation** (not flat synthetic data)
- Clear **volume spikes** in early September and mid-October — likely simulate system incidents or campaign-driven traffic
- Some days show very low volume (10–15 tickets), representing off-peak periods

> **Insight:** Ticket demand is not uniform. Sporadic surges suggest the need for **flexible, on-demand resource planning**.

---

### 2. Escalation Rate Over Time

**Research Question:** Does the escalation rate trend upward, downward, or stay flat over the analysis period? Is it correlated with ticket volume?

```python
import plotly.graph_objects as go

weekly_trend = tickets_enriched.groupby('created_week').agg(
    total=('ticket_id', 'count'),
    escalations=('escalation_flag', 'sum')
).reset_index()
weekly_trend['esc_rate'] = weekly_trend['escalations'] / weekly_trend['total']
weekly_trend['week_label'] = pd.to_datetime(
    weekly_trend['created_week'].str.split('/').str[0]
).dt.strftime('%b %d')

fig = go.Figure()
fig.add_trace(go.Scatter(
    x=weekly_trend['week_label'], y=weekly_trend['esc_rate'],
    mode='lines+markers', line=dict(color='#E84C4C', width=2.5),
    marker=dict(size=8, color='#E84C4C'),
    fill='tozeroy', fillcolor='rgba(232,76,76,0.10)'
))
max_row = weekly_trend.loc[weekly_trend['esc_rate'].idxmax()]
fig.add_annotation(
    x=max_row['week_label'], y=max_row['esc_rate'],
    text=f"Peak {max_row['esc_rate']:.0%}",
    showarrow=True, arrowhead=2, arrowcolor='#E84C4C',
    font=dict(color='#E84C4C', size=12), ax=30, ay=-30
)
fig.update_xaxes(title_text='Week Starting', tickangle=-30)
fig.update_yaxes(title_text='Escalation Rate', tickformat='.0%')
fig.show()
```

- Escalation rate is tracked on a **weekly** and **daily** basis
- Weekly trends show moderate variability across the 8-week analysis window
- Spearman correlation between **ticket volume vs escalation rate** = **-0.58** (weekly) / **-0.03** (daily)
- **p-value = 0.13 / 0.81** → NOT statistically significant at α = 0.05

> **Conclusion:** Escalation rates are **independent of ticket volume**. Escalation is likely driven by *issue complexity or customer segment*, not workload.

![Escalation Rate by Issue Category](../docs/escalation_rate_by%20_issue_category.png)

---

### 3. Weekly SLA Breach Rate Trend

**Research Question:** Is the SLA breach rate improving, worsening, or stable week-over-week?

```python
import plotly.graph_objects as go

sla_trend = tickets_enriched.groupby('created_week').agg(
    sla_breach_rate=('sla_breached_flag', 'mean')
).reset_index()
sla_trend['week_label'] = pd.to_datetime(
    sla_trend['created_week'].str.split('/').str[0]
).dt.strftime('%b %d')

avg_rate = sla_trend['sla_breach_rate'].mean()

fig = go.Figure()
fig.add_trace(go.Scatter(
    x=sla_trend['week_label'], y=sla_trend['sla_breach_rate'],
    mode='lines+markers', line=dict(color='#9B4CE8', width=2.5),
    marker=dict(size=9, color='#9B4CE8'),
    fill='tozeroy', fillcolor='rgba(155,76,232,0.10)'
))
fig.add_hline(
    y=avg_rate, line_dash='dash', line_color='#A0A0A0',
    annotation_text=f'Avg {avg_rate:.0%}', annotation_position='top right'
)
fig.update_xaxes(title_text='Week Starting', tickangle=-30)
fig.update_yaxes(title_text='SLA Breach Rate', tickformat='.0%')
fig.show()
```

- SLA breach rate ranged between **33% and 54%** across weeks
- **Peak around mid-September (~54%)**, declining toward October (~33%)

> **Insight:** SLA performance improves over time, possibly due to process optimisation, better workload handling, or stabilisation after high-demand periods.

---

### 4. Hourly Ticket Creation Pattern

**Research Question:** At what times of day do tickets peak? How should staffing rotas be aligned?

```python
import plotly.graph_objects as go

hourly_trend = tickets_enriched.groupby('created_hour').size().reset_index(name='tickets')
peak_hr = hourly_trend.loc[hourly_trend['tickets'].idxmax()]

fig = go.Figure(go.Bar(
    x=hourly_trend['created_hour'], y=hourly_trend['tickets'],
    marker_color='#4CE8D5', marker_line=dict(width=0),
    hovertemplate='Hour %{x}:00 → %{y} tickets<extra></extra>'
))
fig.add_annotation(
    x=peak_hr['created_hour'], y=peak_hr['tickets'],
    text='Peak hour', showarrow=True, arrowhead=2,
    font=dict(color='#4CE8D5', size=12), ax=0, ay=-35
)
fig.update_xaxes(
    title_text='Hour of Day',
    tickmode='array',
    tickvals=list(range(0, 24)),
    ticktext=[f'{h}:00' for h in range(0, 24)]
)
fig.update_yaxes(title_text='Ticket Count')
fig.show()
```

- Ticket creation follows a **typical business-hour distribution**
- Peak demand occurs around **midday (12 PM)**, with minimal activity during late-night hours (12 AM – 6 AM)

> **Operational Recommendation:** Support teams should be optimally staffed between **9 AM – 2 PM**. Reduced staffing during late-night hours improves efficiency and resource utilisation.

---

### 5. Outlier Detection in Resolution Time

**Research Question:** Are there extreme resolution time outliers, and do they represent genuine process bottlenecks or data anomalies?

```python
import plotly.graph_objects as go
import numpy as np

Q1 = tickets_enriched['resolution_time_hours'].quantile(0.25)
Q3 = tickets_enriched['resolution_time_hours'].quantile(0.75)
IQR = Q3 - Q1
upper_fence = Q3 + 1.5 * IQR

outliers = tickets_enriched[tickets_enriched['resolution_time_hours'] > upper_fence]
normal   = tickets_enriched[tickets_enriched['resolution_time_hours'] <= upper_fence]

fig = go.Figure()
fig.add_trace(go.Scatter(
    x=normal.index, y=normal['resolution_time_hours'],
    mode='markers', name='Normal',
    marker=dict(color='#4C9BE8', size=4, opacity=0.5)
))
fig.add_trace(go.Scatter(
    x=outliers.index, y=outliers['resolution_time_hours'],
    mode='markers', name='Outlier',
    marker=dict(color='#E84C4C', size=7, symbol='x')
))
fig.add_hline(y=upper_fence, line_dash='dash', line_color='#A0A0A0',
              annotation_text=f'IQR fence ({upper_fence:.1f}h)')
fig.update_xaxes(title_text='Ticket Index')
fig.update_yaxes(title_text='Resolution Time (hrs)')
fig.show()
```

- IQR-based outlier detection applied to `resolution_time_mins`
- Extreme resolution-time outliers were **flagged and assessed** as process bottlenecks
- Outliers were **retained** (not dropped) to preserve analytical integrity and inform investigations

---

### 6. Pre- vs Post-Cleaning Validation

**Research Question:** How many columns were added during feature engineering, and does the enriched table preserve data integrity?

```python
import sqlite3

conn = sqlite3.connect('opsSLA.db')

original_cols = pd.read_sql("SELECT * FROM tickets LIMIT 1", conn).shape[1]
enriched_cols = pd.read_sql("SELECT * FROM tickets_esc_summary LIMIT 1", conn).shape[1]

print(f"Original columns : {original_cols}")
print(f"Enriched columns : {enriched_cols}")
print(f"New features added: {enriched_cols - original_cols}")

# Null check on enriched table
null_summary = pd.read_sql("SELECT * FROM tickets_esc_summary", conn).isnull().sum()
print(null_summary[null_summary > 0])
conn.close()
```

- Original `tickets` table: **13 columns**
- Enriched `tickets_esc_summary` table: **35 columns**
- All cleaning and enrichment steps validated for consistency before saving back to the database

> **Result:** Data preparation improved completeness and consistency while preserving analytical integrity.

---

## 📊 Libraries Used

```python
import pandas as pd
import numpy as np
import plotly.graph_objects as go
import plotly.express as px
from plotly.subplots import make_subplots
import sqlite3
from scipy.stats import spearmanr
```

---

## 🔗 Next Step

The enriched `tickets_esc_summary` table produced here is the **primary input** for the deep-dive analysis in the [`Ticket Escalation Summary`](../Ticket%20Escalation%20Summary/) notebook.
