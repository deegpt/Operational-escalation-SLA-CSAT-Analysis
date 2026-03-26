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
CALENDAR(
    MIN(tickets[created_date]),
    MAX(tickets[created_date])
)
```

> **Note:** `CALENDAR(start_date, end_date)` generates one row per date between the two dates.
> `tickets[created_date]` must be a **Date** type column (created in Step 1 Power Query).
> If you skipped that step, use `DATEVALUE(MIN(tickets[created_at]))` instead.

Then add these as **calculated columns** to the DateTable (right-click DateTable → New Column):

```dax
Week Number = WEEKNUM(DateTable[Date], 2)
```
```dax
ISO Week = "W" & FORMAT(WEEKNUM(DateTable[Date], 2), "00")
```
```dax
Day of Week = FORMAT(DateTable[Date], "dddd")
```
```dax
Month Name = FORMAT(DateTable[Date], "MMMM YYYY")
```
```dax
Day Number = WEEKDAY(DateTable[Date], 2)
```

> **Tip:** Add each column one at a time — Power BI does not support multiple column definitions in one expression.

Then relate DateTable to tickets:

| From | Column | To | Column | Cardinality |
|---|---|---|---|---|
| `tickets` | `created_date` | `DateTable` | `Date` | Many to One |

---

## Mark as Date Table

1. Click `DateTable` in Model view
2. Right-click → **Mark as date table**
3. Select the `Date` column

This enables Power BI’s time intelligence functions like `DATESINPERIOD`, `SAMEPERIODLASTYEAR`, and rolling averages used in the WoW DAX measures in Step 3.

---

## Common Errors & Fixes

| Error | Cause | Fix |
|---|---|---|
| `CALENDARFUND is not a valid function` | Typo | Use `CALENDAR()` |
| `Cannot find column tickets[created_date]` | Column not created in Power Query | Add it in Step 1 Power Query M code |
| Relationship shows as dashed line | Duplicate values in a "one" side column | Check `agents[agent_id]` and `customers[customer_id]` for duplicates |
| `DateTable` won't mark as date table | Date column has blanks or non-date values | Filter out nulls in Power Query before loading |

---

## Verification Checklist

- [ ] 5 relationships created, all showing as **solid lines** (not dashed)
- [ ] No ambiguous relationship warnings in Model view
- [ ] `DateTable` marked as date table (calendar icon appears on it)
- [ ] Relationship between `tickets` and `sla_logs` is **1:1**
- [ ] `DateTable[ISO Week]` shows values like `W36`, `W37`, `W38`

---

## Next Step → [Step 3: Write DAX Measures](Step-3-DAX-Measures.md)
