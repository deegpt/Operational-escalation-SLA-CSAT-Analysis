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

### Categorical Distribution Analysis (Countplots)

Countplots were used to examine the distribution of key categorical variables in order to understand ticket volume composition, customer mix, and the nature of issues handled by support operations. These plots are descriptive in nature and are intended to guide subsequent comparative and rate-based analyses.

##### Issue Category

**Variables**: Cards, Payments, Accounts, Compliance, Credit

*Observations:**
- Ticket volume is distributed across multiple issue categories.
- Cards and Payments represent the highest number of tickets.
- Accounts, Compliance, and Credit show comparable volumes with no extreme imbalance.

**Interpretation:**
Support demand is broad-based rather than concentrated, indicating that operational load spans transactional, account-related, and regulatory domains. High volumes in Cards and Payments suggest high-frequency customer interactions, while sustained volume in Compliance and Credit points to ongoing complexity in regulated financial processes.

#### Country

**Variables:** DE, ES, IT, UK, FR

**Observations:**
- Ticket counts are relatively balanced across countries.
- Minor differences exist (e.g., DE and ES slightly higher; FR slightly lower), but no country dominates volume.

**Interpretation:**
Geographic distribution of tickets appears stable, enabling fair cross-country comparisons for SLA compliance, escalation rates, and CSAT without strong volume bias. Any performance differences observed later are more likely attributable to process or policy differences rather than demand skew.

#### Customer Segment

**Variables:** Standard, Plus, Premium, Metal, Ultra

**Observations:**

- Standard customers account for the majority of tickets.
- Plus customers form a secondary cluster.
- Premium, Metal, and Ultra segments represent a smaller proportion of total volume.

**Interpretation:**
Ticket volume is **inversely related to customer plan tier**. While higher-tier customers generate fewer tickets, they may carry higher expectations and stricter SLA sensitivity. Consequently, raw counts should not be used for performance comparison across segments; normalized rates are required.

#### Reason Category

> **Examples:** Credit, Merchant Dispute, Insurance, RevPoints, Chargeback, Account Restriction, etc.

**Observations:**

- Credit-related reasons are the most frequent.
- Disputes, insurance, and rewards form the next most common group.
- A long tail of moderately frequent reasons exists.

**Interpretation:**
Credit and dispute-driven issues constitute a significant portion of support demand and are likely to involve higher complexity. These categories are strong candidates for deeper analysis related to escalation likelihood, resolution time, SLA breaches, and CSAT impact.

---

### Correlation Analysis (Heatmap)

A Pearson correlation heatmap was used to assess linear relationships between numerical and binary variables related to resolution time, escalation behavior, SLA compliance, severity, and customer satisfaction.

#### Strong Positive Correlations
`resolution_time_mins` ↔ `actual_resolution_mins` ↔ `resolution_time_hours` **Correlation ≈ 1.00**

**Resolution Time Metrics**

- resolution_time_mins, actual_resolution_mins, and resolution_time_hours show near-perfect positive correlation.
- These variables represent equivalent measures in different units.

**Interpretation:**
Only one resolution time variable should be retained for modeling or reporting to avoid redundancy.

**SLA Risk and SLA Breach** 

sla_risk_flag and sla_breached_flag exhibit a strong positive correlation (~0.8).

**Interpretation**:
The SLA risk indicator is a strong leading signal of actual SLA breach, validating the risk-flagging logic.

**Severity and Operational Outcomes**
`sla_breached_flag` ↔ `actual_resolution_mins` **Correlation ≈ 0.64**
`severity_score` ↔ `escalation_flag` **Correlation ≈ 0.63**
`severity_score` ↔ `sla_breached_flag` **Correlation ≈ 0.72**

- Longer resolution times strongly increase SLA breach probability. This confirms, SLA breach is primarily time-driven.
- severity_score shows strong positive correlation with:
    - sla_breached_flag
    - escalation_flag
    - resolution time metrics

**Interpretation:**
Higher severity tickets are more complex, take longer to resolve, and are more likely to escalate and breach SLA. This establishes severity as a primary upstream driver of operational strain.

#### Strong Negative Correlations 

**CSAT vs Resolution Time**
`csat_score` ↔ `resolution_time_mins` **Correlation ≈ –0.42**

csat_score is moderately to strongly negatively correlated with resolution time metrics.

**Interpretation:**
Longer resolution times are associated with lower customer satisfaction, indicating speed as a key CSAT driver.

**CSAT vs SLA Breach and Repeat Contact**
`csat_score` ↔ `sla_breached_flag` **Correlation ≈ –0.24 to –0.27**
CSAT shows negative correlation with sla_breached_flag because some customers can still tolerate breaches, though, expectations vary by segment.

`csat_score` ↔ `repeat_contact_flag` **Correlation ≈ –0.36**

**Interpretation:**
Customers are less satisfied when SLAs are breached or when multiple contacts are required, highlighting both timeliness and resolution quality as determinants of experience.
