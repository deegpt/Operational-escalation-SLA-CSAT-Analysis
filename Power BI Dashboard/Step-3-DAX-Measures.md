# Step 3 — DAX Measures

> **Goal:** Create all calculated measures that power every KPI card, chart, and table in the dashboard.
> **Where to create:** In Power BI Desktop → **New Measure** (add all measures to a dedicated `_Measures` table)
> **Time:** ~30 minutes

### Create a Measures Table first

Go to **Home → Enter Data** → name it `_Measures` → Load.
This keeps all your measures in one organised place.

---

## Section 1 — Core Volume Measures

```dax
-- Total number of tickets
Total Tickets =
COUNTROWS(tickets)

-- Total escalated tickets
Total Escalations =
SUM(tickets[escalation_flag])

-- Total SLA breaches
Total SLA Breaches =
SUM(sla_logs[sla_breached_flag])

-- Total repeat contacts
Total Repeat Contacts =
SUM(tickets[repeat_contact_flag])
```

---

## Section 2 — Rate Measures

```dax
-- Escalation Rate %
Escalation Rate % =
DIVIDE([Total Escalations], [Total Tickets], 0)

-- SLA Breach Rate %
SLA Breach Rate % =
DIVIDE([Total SLA Breaches], [Total Tickets], 0)

-- First Contact Resolution Rate %
-- FCR = tickets that did NOT need a repeat contact
FCR Rate % =
DIVIDE(
    COUNTROWS(FILTER(tickets, tickets[repeat_contact_flag] = 0)),
    [Total Tickets],
    0
)

-- Repeat Contact Rate %
Repeat Contact Rate % =
DIVIDE([Total Repeat Contacts], [Total Tickets], 0)
```

---

## Section 3 — CSAT Measures

```dax
-- Average CSAT score
Avg CSAT =
AVERAGE(tickets[csat_score])

-- Average CSAT for escalated tickets only
Avg CSAT (Escalated) =
CALCULATE(
    AVERAGE(tickets[csat_score]),
    tickets[escalation_flag] = 1
)

-- Average CSAT for non-escalated tickets
Avg CSAT (Not Escalated) =
CALCULATE(
    AVERAGE(tickets[csat_score]),
    tickets[escalation_flag] = 0
)

-- Average CSAT for SLA-breached tickets
Avg CSAT (SLA Breached) =
CALCULATE(
    AVERAGE(tickets[csat_score]),
    sla_logs[sla_breached_flag] = 1
)

-- Average CSAT for SLA-compliant tickets
Avg CSAT (SLA Compliant) =
CALCULATE(
    AVERAGE(tickets[csat_score]),
    sla_logs[sla_breached_flag] = 0
)

-- CSAT difference: SLA breach impact
CSAT Impact of SLA Breach =
[Avg CSAT (SLA Compliant)] - [Avg CSAT (SLA Breached)]
```

---

## Section 4 — Resolution Time Measures

```dax
-- Average resolution time in minutes
Avg Resolution (mins) =
AVERAGE(tickets[resolution_time_mins])

-- Average resolution time in hours
Avg Resolution (hrs) =
DIVIDE([Avg Resolution (mins)], 60)

-- Average resolution time for escalated tickets
Avg Resolution (mins, Escalated) =
CALCULATE(
    AVERAGE(tickets[resolution_time_mins]),
    tickets[escalation_flag] = 1
)
```

---

## Section 5 — Agent Health Score

This replicates the composite score from `vw_agent_performance_scorecard`:
```
Health Score = (Avg CSAT / 5) × 40  +  (1 − Esc Rate) × 30  +  (1 − SLA Breach Rate) × 30
```

```dax
Agent Health Score =
VAR AvgCSAT      = AVERAGE(tickets[csat_score])
VAR EscRate      = DIVIDE(SUM(tickets[escalation_flag]), COUNTROWS(tickets), 0)
VAR BreachRate   = DIVIDE(SUM(sla_logs[sla_breached_flag]), COUNTROWS(tickets), 0)
RETURN
    ROUND(
        (AvgCSAT / 5) * 40
        + (1 - EscRate)    * 30
        + (1 - BreachRate) * 30,
    1)
```

---

## Section 6 — Week-over-Week (WoW) Measures

> These require the `DateTable` from Step 2.

```dax
-- SLA Breach Rate this week
SLA Breach Rate (This Week) =
CALCULATE(
    [SLA Breach Rate %],
    DATESINPERIOD(DateTable[Date], LASTDATE(DateTable[Date]), -7, DAY)
)

-- SLA Breach Rate last week
SLA Breach Rate (Last Week) =
CALCULATE(
    [SLA Breach Rate %],
    DATESINPERIOD(DateTable[Date], LASTDATE(DateTable[Date]), -14, DAY),
    NOT DATESINPERIOD(DateTable[Date], LASTDATE(DateTable[Date]), -7, DAY)
)

-- WoW change in SLA Breach Rate
SLA Breach WoW Change =
[SLA Breach Rate (This Week)] - [SLA Breach Rate (Last Week)]

-- WoW change direction label
SLA Breach WoW Label =
VAR Change = [SLA Breach WoW Change]
RETURN
    SWITCH(
        TRUE(),
        Change < 0,  "▼ Improved by " & FORMAT(ABS(Change), "0.0%"),
        Change > 0,  "▲ Worsened by " & FORMAT(Change, "0.0%"),
        "→ No change"
    )

-- 4-week rolling average SLA breach rate
SLA Breach Rate (4Wk Rolling) =
CALCULATE(
    [SLA Breach Rate %],
    DATESINPERIOD(DateTable[Date], LASTDATE(DateTable[Date]), -28, DAY)
)
```

---

## Section 7 — Severity Score Measures

```dax
-- Count of severity score = 3 (all three failure flags)
Critical Tickets (Sev 3) =
CALCULATE(
    COUNTROWS(tickets),
    tickets[severity_score] = 3
)

-- % of tickets that are severity 3
Critical Ticket Rate % =
DIVIDE([Critical Tickets (Sev 3)], [Total Tickets], 0)
```

---

## Section 8 — High-Risk Customer Measures

```dax
-- Tickets from high-risk customers (risk_flag = 1)
High Risk Tickets =
CALCULATE(
    COUNTROWS(tickets),
    customers[risk_flag] = 1
)

-- High-risk tickets that also breached SLA
High Risk + SLA Breach =
CALCULATE(
    COUNTROWS(tickets),
    customers[risk_flag] = 1,
    sla_logs[sla_breached_flag] = 1
)

-- % of high-risk tickets that breached SLA
High Risk SLA Breach Rate % =
DIVIDE([High Risk + SLA Breach], [High Risk Tickets], 0)
```

---

## Verification Checklist

- [ ] All measures visible under `_Measures` table in Data pane
- [ ] `Escalation Rate %` returns ~0.25–0.28 (25–28%) for full dataset
- [ ] `SLA Breach Rate %` returns ~0.33–0.54 depending on date filter
- [ ] `Avg CSAT` returns approximately 3.1–3.2
- [ ] `Agent Health Score` returns a value between 0–100 per agent

---

## Next Step → [Step 4: Build the Dashboard Pages](Step-4-Dashboard-Layout.md)
