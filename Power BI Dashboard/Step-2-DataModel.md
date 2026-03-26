# Step 2 — Build the Data Model (Star Schema)

> **Goal:** Create all table relationships so every visual can be sliced by agent, customer, issue, time, and SLA simultaneously.
> **Time:** ~10 minutes

---

## Star Schema Design

```
                    escalation_reasons
                    (escalation_reason_id)
                             |
                             │ 1
                             ▼
 agents ──────────── tickets (FACT) ──────────── customers
 (agent_id)    *  1  (agent_id)  1  *             (customer_id)
                     (customer_id)
                     (escalation_reason_id)
                             │ 1
                             ▼  *
                          sla_logs
                          (ticket_id)
```

`tickets` is your **fact table** — it sits at the centre.
All other tables are **dimension tables** that describe who, why, and how.

---

## How to Create Relationships in Power BI

1. Click the **Model view** icon (left sidebar, looks like 3 connected boxes)
2. Drag and drop to create each relationship below:

| From Table | From Column | To Table | To Column | Cardinality | Filter Direction |
|---|---|---|---|---|---|
| `tickets` | `agent_id` | `agents` | `agent_id` | Many to One (\*:1) | Single (agents → tickets) |
| `tickets` | `customer_id` | `customers` | `customer_id` | Many to One (\*:1) | Single (customers → tickets) |
| `tickets` | `ticket_id` | `sla_logs` | `ticket_id` | One to One (1:1) | Both |
| `tickets` | `escalation_reason_id` | `escalation_reasons` | `escalation_reason_id` | Many to One (\*:1) | Single (escalation_reasons → tickets) |

---

## Create a Date Table (Required for WoW measures)

Go to **Home → New Table** and paste this DAX:

```dax
DateTable =
CALENDARFUND(
    MIN(tickets[created_date]),
    MAX(tickets[created_date])
)
```

Then add calculated columns to the DateTable:

```dax
-- Add to DateTable as calculated columns (New Column)
Week Number  = WEEKNUM(DateTable[Date], 2)
ISO Week     = "W" & FORMAT(WEEKNUM(DateTable[Date],2), "00")
Day of Week  = FORMAT(DateTable[Date], "dddd")
Month Name   = FORMAT(DateTable[Date], "MMMM YYYY")
Day Number   = WEEKDAY(DateTable[Date], 2)
```

Then relate:

| From | Column | To | Column | Cardinality |
|---|---|---|---|---|
| `tickets` | `created_date` | `DateTable` | `Date` | Many to One |

---

## Mark as Date Table

1. Click the `DateTable` in Model view
2. Right-click → **Mark as date table**
3. Select the `Date` column

This enables Power BI's time intelligence functions (WoW, MoM, rolling averages).

---

## Verification Checklist

- [ ] 5 relationships created, all showing as solid lines (not dashed)
- [ ] No ambiguous relationship warnings in Model view
- [ ] `DateTable` marked as date table
- [ ] Relationship between `tickets` and `sla_logs` is **1:1** (not 1:many)

---

## Next Step → [Step 3: Write DAX Measures](Step-3-DAX-Measures.md)
