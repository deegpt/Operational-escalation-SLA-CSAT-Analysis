# 📊 Operational Escalation, SLA & CSAT Analysis

> **Domain:** FinTech Customer Support Operations | **Stack:** Python · SQL · SQLite · Pandas · Seaborn · Matplotlib · SciPy

A end-to-end data analysis project that explores **1,200 support tickets** from a simulated FinTech (Revolut-style) operations environment. The project identifies key drivers of **escalations**, **SLA breaches**, **repeat contacts**, and **customer satisfaction (CSAT)**, delivering actionable insights for process improvement, staffing optimisation, and workflow redesign.

---

## 🗂️ Project Structure

```
Operational-escalation-SLA-CSAT-Analysis/
│
├── Data Ingestion/                    # Database schema creation & synthetic data generation
│   └── ...                            
│
├── Exploratory Data Analysis/         # Full EDA notebook — trends, patterns, correlations
│   ├── Exploratory-Data-Analysis.ipynb
│   └── README.md
│
├── Ticket Escalation Summary/         # Escalation, SLA & CSAT deep-dive analysis notebook
│   ├── Escalation_SLA_CSAT_Analysis.ipynb
│   └── README.md
│
├── docs/                              # Supporting documentation
├── LICENSE
└── README.md                          ← You are here
```

---

## 🗃️ Database Schema

The project uses a **SQLite database** (`opsSLA.db`) with the following relational tables:

| Table | Rows | Description |
|---|---|---|
| `tickets` | 1,200 | Core ticket data — category, agent, customer, CSAT, payment type, country |
| `sla_logs` | 1,200 | SLA target vs actual resolution time, breach flag & reason |
| `agents` | 100 | Agent tier (L1/L2/L3), region (EMEA/APAC), experience (months) |
| `customers` | 500 | Customer segment (Standard/Metal/Premium), tenure, risk flag |
| `escalation_reasons` | 15 | Reason categories: Chargeback, Insurance, RevPoints, Plan Benefits, etc. |
| `tickets_esc_summary` | 1,200 | Enriched master view joining all tables with engineered features |

---

## 🔑 Key Features Engineered

- `resolution_time_hours` — resolution time converted from minutes to hours
- `sla_risk_flag` — boolean flag for SLA at-risk tickets
- `resolution_speed` — categorical: Fast / Moderate / Slow
- `severity_score` — composite score from escalation + SLA breach + repeat contact
- `created_date`, `created_week`, `created_month`, `created_hour`, `created_dow` — temporal breakdown features

---

## 📁 Analysis Modules

### 1. [Exploratory Data Analysis](./Exploratory%20Data%20Analysis/)
Data quality auditing, temporal trend analysis, statistical validation of escalation & SLA patterns across time, agents, regions, and customer segments.

### 2. [Ticket Escalation, SLA & CSAT Analysis](./Ticket%20Escalation%20Summary/)
Deep-dive analysis into escalation drivers, SLA breach root causes, CSAT distribution, agent performance benchmarking, and repeat contact behaviour.

---

## 🛠️ Tech Stack

| Tool | Purpose |
|---|---|
| **Python 3** | Core analysis language |
| **SQLite + `sqlite3`** | Relational data storage and SQL querying |
| **Pandas** | Data wrangling and feature engineering |
| **NumPy** | Numerical operations |
| **Matplotlib + Seaborn** | Data visualisation |
| **SciPy** | Statistical testing (Spearman correlation, t-tests) |
| **Jupyter Notebook** | Interactive analysis environment |

---

## 📌 Key Business Insights

- 📈 **SLA breach rate** ranged between **33–54%**, with a declining trend over the analysis period — suggesting process stabilisation over time
- 🔁 **Escalation rates are independent of ticket volume** — Spearman correlation = -0.03, p = 0.81 (not significant), meaning escalation is driven by ticket *complexity*, not volume
- ⏰ **Peak ticket creation** occurs between **9 AM – 2 PM**, highlighting the need for staffing alignment to business hours
- 🧑‍💼 **Agent tier and experience** significantly impact resolution speed and CSAT scores
- 🗺️ **Regional disparities** exist between EMEA and APAC agents in escalation and SLA metrics
- 💳 **Payment type** (WALLET / CARD / BANK_TRANSFER) and **issue category** (Cards, Payments, Compliance, Credit) are strong escalation predictors

---

## ⚡ Process Recommendations

1. Increase L2 staffing during **historically high-volume weekdays**
2. Introduce **proactive escalation monitoring** during mid-week peaks
3. Adjust **weekend staffing** to reduce SLA breach risk
4. Use **rolling weekly escalation rate** as an early-warning KPI
5. Align support staffing to **9 AM – 2 PM peak window** for optimal SLA performance

---

## 🚀 Getting Started

```bash
# 1. Clone the repo
git clone https://github.com/deegpt/Operational-escalation-SLA-CSAT-Analysis.git
cd Operational-escalation-SLA-CSAT-Analysis

# 2. Install dependencies
pip install pandas numpy matplotlib seaborn scipy jupyter

# 3. Launch notebooks
jupyter notebook
```

> **Note:** The SQLite database `opsSLA.db` must be present in the working directory when running the notebooks.

---

## 👤 Author

**Deepak Gupta** · Data Analyst Enthusiast | Python · SQL · Tableau · Power BI

[![GitHub](https://img.shields.io/badge/GitHub-deegpt-black?logo=github)](https://github.com/deegpt)
[![Portfolio](https://img.shields.io/badge/Portfolio-deegpt.github.io-blue)](https://deegpt.github.io/deegpt2.github.io/)

---

## 📄 License

This project is licensed under the [MIT License](./LICENSE).
