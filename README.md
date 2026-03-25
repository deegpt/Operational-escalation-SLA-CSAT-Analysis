# Operational-escalation-SLA-CSAT-Analysis

🚀 ### Project Overview

This project simulates a real-world fintech support operations environment, focusing on:

- Ticket lifecycle analysis
- Escalation drivers
- SLA performance
- Customer satisfaction (CSAT)
- Operational efficiency

The goal is to demonstrate end-to-end analytics capability, including:

- Data modeling
- SQL-based analysis
- Python EDA
- Business insights & recommendations

---

🧩 ### Dataset Description

The project uses a relational dataset consisting of 5 tables:

1. `tickets` (Fact Table)
- Core operational data (~1200 records)
- Contains ticket lifecycle, resolution, and customer experience metrics

3. `customers`
- ~500 customers
- Includes customer segments:
    - Standard, Plus, Premium, Metal, Ultra
      
4. `agents`
- ~100 support agents
- Includes tier, region, and experience
  
5. `escalation_reasons`
- 15 categorized escalation drivers
- Represents real fintech scenarios
  
6. `sla_logs`
- SLA targets vs actual resolution times
- SLA breach indicators

---

🧱 ### Data Model (Star Schema)

customers        agents        escalation_reasons
     │              │                 │
     └──────┬───────┴───────┬─────────┘
            │               │
         tickets (FACT) ────┘
            │
        sla_logs

---

🛠️ ### Tools & Technologies
- SQL Server — Data modeling, joins, window functions
- Python (Pandas, Matplotlib) — EDA & statistical validation
- Jupyter Notebook — Analysis workflow
- Power BI (optional) — Dashboarding

---

🔍 ### Key Analysis Areas

1️⃣ Escalation Drivers
- Identified issue categories with highest escalation rates
- Used aggregation + statistical validation (Chi-square)
  
2️⃣ Resolution Time vs CSAT
- Longer resolution times significantly reduce CSAT
- Validated using Spearman correlation
  
3️⃣ SLA Performance
- SLA breach patterns across issue categories
- Identified operational bottlenecks
  
4️⃣ Agent Performance
- Compared L1 vs L2 performance
- Measured impact on resolution time and escalations
  
5️⃣ Repeat Contact Analysis
- Identified drivers of repeat customer contacts
- Strong link to poor resolution quality

📈 ### Temporal & Trend Analysis

- Weekly ticket volume trends
- Escalation rate trends
- Rolling averages for noise reduction
- Control charts to detect abnormal process behavior

🧠 ### Key Insights

- Escalations are concentrated in Payments & Compliance issues
- Resolution time is a strong driver of CSAT decline
- SLA breaches increase during high workload periods
- Repeat contacts indicate ineffective first resolution
- Certain issue categories consistently underperform

💡 ### Business Recommendations

- Increase L2 support for high-risk issue categories
- Introduce proactive monitoring for SLA breach risk
- Optimize staffing during peak demand periods
- Improve first-contact resolution processes
- Track rolling escalation rates as early warning signals

⚙️ ### Data Engineering Highlights

- Designed relational schema with fact & dimension tables
- Implemented clean, SQL Server–compatible datasets
Ensured:
- Consistent datetime formats
- Referential integrity
- No duplicate primary keys
- Built staging → clean load pipeline logic

📌 ### Example SQL Capabilities Demonstrated

- Aggregations & joins
- Window functions (RANK, LAG, rolling averages)
- SLA calculations
- Behavioral analysis queries

📌 ### Example SQL Capabilities Demonstrated

- Aggregations & joins
- Window functions (RANK, LAG, rolling averages)
- SLA calculations
- Behavioral analysis queries

📊 ### Example Python Capabilities Demonstrated

- Data cleaning & validation
- Feature engineering
- Correlation analysis
- Statistical testing
- Visualization (line plots, heatmaps, distributions)

📁 ### Project Structure

operations-sla-analytics/
│
├── data/
│   ├── agents.csv
│   ├── customers.csv
│   ├── escalation_reasons.csv
│   ├── tickets.csv
│   └── sla_logs.csv
│
├── sql/
│   ├── schema.sql
│   ├── analysis_queries.sql
│
├── notebooks/
│   ├── eda_analysis.ipynb
│   └── trend_analysis.ipynb
│
├── powerbi/
│   └── dashboard.pbix
│
└── README.md

🎯 ### What This Project Demonstrates

- Strong SQL fundamentals beyond basic queries
- Ability to translate business problems into analysis
- Understanding of operational KPIs (SLA, CSAT, escalations)
- Data cleaning and validation in real-world scenarios
- Structured, end-to-end analytics thinking

📌 ### Future Enhancements

- Predict SLA breaches using machine learning
- Real-time dashboard integration
- Agent-level performance scoring model
- Customer churn prediction based on support experience

⭐ ### Final Note

This project reflects a realistic business analytics workflow, combining:

- Data engineering
- SQL analysis
- Statistical reasoning
- Business storytelling
  
