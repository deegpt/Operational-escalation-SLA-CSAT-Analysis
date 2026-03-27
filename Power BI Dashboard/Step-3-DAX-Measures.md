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
Total Tickets =
COUNTROWS(tickets)
```
```dax
Total Escalations =
SUM(tickets[escalation_flag])
```
```dax
Total SLA Breaches =
SUM(sla_logs[sla_breached_flag])
```
```dax
Total Repeat Contacts =
SUM(tickets[repeat_contact_flag])
```

---

## Section 2 — Rate Measures

```dax
Escalation Rate % =
DIVIDE([Total Escalations], [Total Tickets], 0)
```
```dax
SLA Breach Rate % =
DIVIDE([Total SLA Breaches], [Total Tickets], 0)
```
```dax
FCR Rate % =
DIVIDE(
    COUNTROWS(FILTER(tickets, tickets[repeat_contact_flag] = 0)),
    [Total Tickets],
    0
)
```
```dax
Repeat Contact Rate % =
DIVIDE([Total Repeat Contacts], [Total Tickets], 0)
```

---

## Section 3 — CSAT Measures

```dax
Avg CSAT =
AVERAGE(tickets[csat_score])
```
```dax
Avg CSAT (Escalated) =
CALCULATE(
    AVERAGE(tickets[csat_score]),
    tickets[escalation_flag] = 1
)
```
```dax
Avg CSAT (Not Escalated) =
CALCULATE(
    AVERAGE(tickets[csat_score]),
    tickets[escalation_flag] = 0
)
```
```dax
Avg CSAT (SLA Breached) =
CALCULATE(
    AVERAGE(tickets[csat_score]),
    sla_logs[sla_breached_flag] = 1
)
```
```dax
Avg CSAT (SLA Compliant) =
CALCULATE(
    AVERAGE(tickets[csat_score]),
    sla_logs[sla_breached_flag] = 0
)
```
```dax
CSAT Impact of SLA Breach =
[Avg CSAT (SLA Compliant)] - [Avg CSAT (SLA Breached)]
```

---

## Section 4 — Resolution Time Measures

```dax
Avg Resolution (mins) =
AVERAGE(tickets[resolution_time_mins])
```
```dax
Avg Resolution (hrs) =
DIVIDE([Avg Resolution (mins)], 60)
```
```dax
Avg Resolution (mins, Escalated) =
CALCULATE(
    AVERAGE(tickets[resolution_time_mins]),
    tickets[escalation_flag] = 1
)
```

---

## Section 5 — Agent Health Score

`Health Score = (Avg CSAT / 5) × 40 + (1 − Esc Rate) × 30 + (1 − SLA Breach Rate) × 30`

```dax
Agent Health Score =
VAR AvgCSAT    = AVERAGE(tickets[csat_score])
VAR EscRate    = DIVIDE(SUM(tickets[escalation_flag]), COUNTROWS(tickets), 0)
VAR BreachRate = DIVIDE(SUM(sla_logs[sla_breached_flag]), COUNTROWS(tickets), 0)
RETURN
    ROUND(
        (AvgCSAT / 5) * 40
        + (1 - EscRate)    * 30
        + (1 - BreachRate) * 30,
    1)
```

---

## Section 6 — Week-over-Week (WoW) Measures ✅ Fixed

> Requires the `DateTable` from Step 2.

```dax
SLA Breach Rate (This Week) =
CALCULATE(
    [SLA Breach Rate %],
    DATESINPERIOD(DateTable[Date], LASTDATE(DateTable[Date]), -7, DAY)
)
```

```dax
-- ✅ FIXED: Use DATESBETWEEN with explicit VAR dates instead of NOT DATESINPERIOD
-- DAX does not support NOT wrapping a table function like DATESINPERIOD inside CALCULATE.
-- Solution: compute the last-week window as an explicit date range using DATESBETWEEN.
SLA Breach Rate (Last Week) =
VAR LastDate     = LASTDATE(DateTable[Date])
VAR WeekStart    = LastDate - 14   -- 14 days back = start of last week window
VAR WeekEnd      = LastDate - 8    -- 8 days back  = end of last week window
RETURN
    CALCULATE(
        [SLA Breach Rate %],
        DATESBETWEEN(DateTable[Date], WeekStart, WeekEnd)
    )
```

```dax
SLA Breach WoW Change =
[SLA Breach Rate (This Week)] - [SLA Breach Rate (Last Week)]
```
```dax
SLA Breach WoW Label =
VAR Change = [SLA Breach WoW Change]
RETURN
    SWITCH(
        TRUE(),
        Change < 0, "▼ Improved by " & FORMAT(ABS(Change), "0.0%"),
        Change > 0, "▲ Worsened by " & FORMAT(Change, "0.0%"),
        "→ No change"
    )
```
```dax
SLA Breach Rate (4Wk Rolling) =
CALCULATE(
    [SLA Breach Rate %],
    DATESINPERIOD(DateTable[Date], LASTDATE(DateTable[Date]), -28, DAY)
)
```

---

## Section 7 — Severity Score Measures ✅ Fixed

> `severity_score` is a **derived column computed in Python**
> (`escalation_flag + sla_breached_flag + repeat_contact_flag`).
> It does **not exist** in the raw CSV files.
> These measures reproduce the exact same logic using the 3 individual flag columns.

```dax
Critical Tickets (Sev 3) =
CALCULATE(
    COUNTROWS(tickets),
    tickets[escalation_flag]     = 1,
    tickets[repeat_contact_flag] = 1,
    sla_logs[sla_breached_flag]  = 1
)
```
```dax
Critical Ticket Rate % =
DIVIDE(
    CALCULATE(
        COUNTROWS(tickets),
        tickets[escalation_flag]     = 1,
        tickets[repeat_contact_flag] = 1,
        sla_logs[sla_breached_flag]  = 1
    ),
    [Total Tickets],
    0
)
```

---

## Section 8 — High-Risk Customer Measures

```dax
High Risk Tickets =
CALCULATE(
    COUNTROWS(tickets),
    customers[risk_flag] = 1
)
```
```dax
High Risk + SLA Breach =
CALCULATE(
    COUNTROWS(tickets),
    customers[risk_flag]        = 1,
    sla_logs[sla_breached_flag] = 1
)
```
```dax
High Risk SLA Breach Rate % =
DIVIDE([High Risk + SLA Breach], [High Risk Tickets], 0)
```

---

## Common DAX Errors & Fixes

| Error | Root cause | Fix |
|---|---|---|
| `True/False expression does not specify a column` | `NOT` cannot wrap a table function like `DATESINPERIOD` in CALCULATE | Use `DATESBETWEEN` with explicit `VAR` date variables instead |
| `Column 'severity_score' cannot be found` | Column only exists in the Python-enriched table, not raw CSV | Use the Section 7 fixed measures above |
| `This expression refers to a Measure that has an error` | A measure depends on another broken measure | Fix the root dependency first; or inline the logic |
| `Cannot find column tickets[created_date]` | Power Query Step 1 column not added | Add `created_date` in Power Query or use `DATEVALUE(tickets[created_at])` |
| `A circular dependency was detected` | Measure references itself indirectly | Rewrite using `VAR` to break the cycle |
| `DATESINPERIOD requires a date column` | DateTable not marked as date table | Right-click DateTable → Mark as date table |
| `sla_logs column cannot be determined` | Relationship between tickets and sla_logs inactive | Check Model view — ensure 1:1 solid line relationship exists |

---

## Verification Checklist

- [ ] All measures visible under `_Measures` table in the Data pane
- [ ] `Escalation Rate %` returns ~0.25–0.28 for full dataset
- [ ] `SLA Breach Rate %` returns ~0.33–0.54 depending on date filter
- [ ] `Avg CSAT` returns approximately 3.1–3.2
- [ ] `Agent Health Score` returns a value between 0–100 per agent
- [ ] `Critical Ticket Rate %` returns without error ✅
- [ ] `SLA Breach Rate (Last Week)` returns without error ✅

---

## Next Step → [Step 4: Build the Dashboard Pages](Step-4-Dashboard-Layout.md)
