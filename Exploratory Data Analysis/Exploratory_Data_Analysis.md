# Exploratory Data Analysis (EDA)

## Objective of EDA

The objective of the exploratory data analysis is to understand the distributional characteristics, variability, and potential anomalies in ticket resolution performance, escalation behavior, SLA compliance, and customer satisfaction. Particular attention is given to identifying whether extreme values represent data quality issues or genuine operational behavior.

---

### Distribution and Variability Analysis

#### Resolution Time Metrics

**Variables analyzed:**

- `resolution_time_mins`
- `actual_resolution_mins`
- `resolution_time_hours`

**Observations:**

- Resolution time metrics exhibit **high dispersion**, with a **wide interquartile range** (IQR).
- The median is positioned toward the lower end of the scale, while a substantial number of observations extend far beyond the upper quartile.
- The distributions are strongly **right-skewed**, with numerous IQR-defined outliers on the upper end.

There is no evidence of a tightly clustered central tendency.

**Interpretation:**
The large number of high-end outliers indicates **`process variability rather than isolated anomalies`**. Long resolution times are recurring and represent genuine operational behavior that materially affects SLA compliance and customer experience.

**Treatment Decision:**
No outliers were removed or capped for resolution time variables, as these values constitute the core signal for SLA breach and escalation analysis.


#### SLA Target and Compliance Metrics

**Variables analyzed:**

- `sla_target_mins`
- `sla_breached_flag`
- `sla_risk_flag`

**Observations:**

- sla_target_mins shows a **broad spread**, reflecting multiple SLA policies rather than a single standard target.
- Higher SLA targets appear as upper-end values and are not isolated anomalies.
- Binary SLA flags (sla_breached_flag, sla_risk_flag) span the full 0–1 range in boxplots.

**Interpretation:**
Variation in SLA targets is **policy-driven**, not indicative of data quality issues. Boxplots are not suitable for identifying outliers in binary variables, and no meaningful outliers are detected for SLA flags.

**Treatment Decision:**
SLA target variation is retained as an explanatory feature. Binary SLA indicators are treated as categorical variables.


#### Escalation and Risk Indicators

**Variables analyzed**:

- `escalation_flag`
- `risk_flag`
- `repeat_contact_flag`

**Observations:**

- Binary escalation and risk indicators display full-range dispersion in boxplots.
- No statistically defined outliers are present due to the binary nature of these variables.

**Interpretation:**
These indicators represent **low-to-moderate frequency operational events**, not anomalies. Boxplots do not provide meaningful insight for outlier detection on binary data.

**Treatment Decision:**
All escalation and risk flags are retained without modification and analyzed through categorical and rate-based methods.

#### Customer Satisfaction and Severity

**Variables analyzed:**

- `csat_score`
- `severity_score`

**Observations:**

- CSAT scores are centered around neutral to positive values, with occasional low-end outliers.
- Severity scores are concentrated at lower levels, with a small number of high-severity observations.

**Interpretation:**
Low CSAT and high severity values represent **valid but infrequent adverse outcomes** and are essential for root-cause analysis.

**Treatment Decision:**
No outliers were removed. These values are explicitly analyzed in relation to SLA breaches and escalations.

---
