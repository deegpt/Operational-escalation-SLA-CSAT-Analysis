# Step 1 — Connect Your Data in Power BI (Power Query)

> **Goal:** Load all 5 tables from your CSV files into Power BI Desktop, apply correct data types,
> and recreate all date-derived feature columns that exist in `tickets_enriched` from the Python notebook.
> **Time:** ~20 minutes

---

## Option A — Connect via CSV Files (Recommended)

1. Click **Home → Get Data → Text/CSV**
2. Load each file one at a time:

| File | Power BI Table Name |
|---|---|
| `tickets.csv` | `tickets` |
| `agents.csv` | `agents` |
| `customers.csv` | `customers` |
| `sla_logs.csv` | `sla_logs` |
| `escalation_reasons.csv` | `escalation_reasons` |

3. After loading, click **Transform Data** to open Power Query Editor

---

## Option B — Connect via SQLite (`opsSLA.db`)

Power BI has no native SQLite connector. Export to CSV from Python first:

```python
import sqlite3, pandas as pd
conn = sqlite3.connect('opsSLA.db')
for table in ['tickets','agents','customers','sla_logs','escalation_reasons']:
    pd.read_sql(f'SELECT * FROM {table}', conn).to_csv(f'data/{table}.csv', index=False)
```

---

## Full Power Query M Code — `tickets` Table

This single M script:
- Loads the CSV
- Fixes all column data types
- Recreates **all 8 date feature columns** from `tickets_enriched`

Go to **Home → Advanced Editor** inside the `tickets` query and replace everything with:

```m
let
    // ── 1. Load CSV ─────────────────────────────────────────────────────────────
    Source = Csv.Document(
        File.Contents("C:\\path\\to\\data\\tickets.csv"),
        [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.None]
    ),
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),

    // ── 2. Fix data types ────────────────────────────────────────────────────────
    ChangedTypes = Table.TransformColumnTypes(PromotedHeaders, {
        {"ticket_id",             Int64.Type},
        {"created_at",            type datetime},
        {"customer_id",           Int64.Type},
        {"agent_id",              Int64.Type},
        {"escalation_reason_id",  Int64.Type},
        {"resolution_time_mins",  Int64.Type},
        {"resolution_time_hours", type number},
        {"csat_score",            Int64.Type},
        {"escalation_flag",       Int64.Type},
        {"sla_breached_flag",     Int64.Type},
        {"repeat_contact_flag",   Int64.Type}
    }),

    // ── 3. created_date  (date only, no time) ────────────────────────────────
    // Python: tickets_enriched['created_date'] = tickets['created_at'].dt.date
    AddedDate = Table.AddColumn(
        ChangedTypes, "created_date",
        each DateTime.Date([created_at]),
        type date
    ),

    // ── 4. created_hour  (0–23) ───────────────────────────────────────────────
    // Python: tickets_enriched['created_hour'] = tickets['created_at'].dt.hour
    AddedHour = Table.AddColumn(
        AddedDate, "created_hour",
        each Time.Hour(DateTime.Time([created_at])),
        Int64.Type
    ),

    // ── 5. created_dow  (Monday, Tuesday … Sunday) ─────────────────────────
    // Python: tickets_enriched['created_dow'] = tickets['created_at'].dt.day_name()
    AddedDOW = Table.AddColumn(
        AddedHour, "created_dow",
        each Date.DayOfWeekName(DateTime.Date([created_at])),
        type text
    ),

    // ── 6. created_dow_num  (1=Mon … 7=Sun) for correct sort order ──────────────
    // Python: tickets_enriched['created_dow_num'] = tickets['created_at'].dt.dayofweek
    AddedDOWNum = Table.AddColumn(
        AddedDOW, "created_dow_num",
        each Date.DayOfWeek(DateTime.Date([created_at]), Day.Monday) + 1,
        Int64.Type
    ),

    // ── 7. created_month  ("September 2025", "October 2025") ───────────────────
    // Python: tickets_enriched['created_month'] = tickets['created_at'].dt.to_period('M')
    AddedMonth = Table.AddColumn(
        AddedDOWNum, "created_month",
        each Date.ToText(DateTime.Date([created_at]), "MMMM yyyy"),
        type text
    ),

    // ── 8. created_week  ("2025-W36", "2025-W37" …) ────────────────────────
    // Python: tickets_enriched['created_week'] = tickets['created_at'].dt.isocalendar().week
    AddedWeek = Table.AddColumn(
        AddedMonth, "created_week",
        each
            Text.From(Date.Year(DateTime.Date([created_at])))
            & "-W"
            & Text.PadStart(
                Text.From(Date.WeekOfYear(DateTime.Date([created_at]))),
                2, "0"
              ),
        type text
    ),

    // ── 9. is_weekend  (1 = Sat/Sun, 0 = weekday) ────────────────────────────
    // Python: tickets_enriched['is_weekend'] = tickets['created_at'].dt.dayofweek >= 5
    AddedWeekend = Table.AddColumn(
        AddedWeek, "is_weekend",
        each if Date.DayOfWeek(DateTime.Date([created_at]), Day.Monday) >= 5 then 1 else 0,
        Int64.Type
    ),

    // ── 10. peak_hour_flag  (1 if hour between 9–14, else 0) ────────────────────
    // Python: tickets_enriched['peak_hour_flag'] based on EDA peak window 9 AM–2 PM
    AddedPeakHour = Table.AddColumn(
        AddedWeekend, "peak_hour_flag",
        each if [created_hour] >= 9 and [created_hour] <= 14 then 1 else 0,
        Int64.Type
    )

in
    AddedPeakHour
```

> **Note:** Update `"C:\\path\\to\\data\\tickets.csv"` to your actual file path.
> If you are on Mac/Linux use forward slashes: `"/Users/yourname/data/tickets.csv"`

---

## What Each Column Maps To

| Power Query Column | Python Equivalent | Type | Used For |
|---|---|---|---|
| `created_date` | `.dt.date` | Date | DateTable relationship, trend charts |
| `created_hour` | `.dt.hour` | Whole Number | Hourly heatmap, peak hour analysis |
| `created_dow` | `.dt.day_name()` | Text | Day-of-week bar charts |
| `created_dow_num` | `.dt.dayofweek` | Whole Number | Sorting `created_dow` Mon→Sun |
| `created_month` | `.dt.to_period('M')` | Text | Monthly grouping |
| `created_week` | `.dt.isocalendar().week` | Text | Weekly trend line X-axis |
| `is_weekend` | `dayofweek >= 5` | Whole Number (0/1) | Weekend vs weekday filter |
| `peak_hour_flag` | `hour between 9–14` | Whole Number (0/1) | Peak staffing analysis |

---

## Sort `created_dow` Correctly (Mon → Sun)

By default Power BI sorts text columns A→Z, so `created_dow` will sort as:
Friday, Monday, Saturday... instead of Monday, Tuesday...

Fix this in Power BI Desktop (not Power Query):
1. Click the `tickets` table in **Data view**
2. Click the `created_dow` column header
3. Go to **Column tools → Sort by column → select `created_dow_num`**

Now all day-of-week charts will sort Mon → Tue → Wed → Thu → Fri → Sat → Sun automatically.

---

## `agents` Table Type Fixes

```m
let
    Source           = Csv.Document(File.Contents("C:\\path\\to\\data\\agents.csv"), [Delimiter=",", Encoding=65001]),
    PromotedHeaders  = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    ChangedTypes     = Table.TransformColumnTypes(PromotedHeaders, {
        {"agent_id",          Int64.Type},
        {"experience_months", Int64.Type}
    })
in
    ChangedTypes
```

## `customers` Table Type Fixes

```m
let
    Source          = Csv.Document(File.Contents("C:\\path\\to\\data\\customers.csv"), [Delimiter=",", Encoding=65001]),
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    ChangedTypes    = Table.TransformColumnTypes(PromotedHeaders, {
        {"customer_id",    Int64.Type},
        {"tenure_months",  Int64.Type},
        {"risk_flag",      Int64.Type}
    })
in
    ChangedTypes
```

## `sla_logs` Table Type Fixes

```m
let
    Source          = Csv.Document(File.Contents("C:\\path\\to\\data\\sla_logs.csv"), [Delimiter=",", Encoding=65001]),
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    ChangedTypes    = Table.TransformColumnTypes(PromotedHeaders, {
        {"ticket_id",              Int64.Type},
        {"sla_target_mins",        Int64.Type},
        {"actual_resolution_mins", Int64.Type},
        {"sla_breached_flag",      Int64.Type}
    })
in
    ChangedTypes
```

---

## Verification Checklist

- [ ] `tickets` table has **8 new columns** after `created_at`: `created_date`, `created_hour`, `created_dow`, `created_dow_num`, `created_month`, `created_week`, `is_weekend`, `peak_hour_flag`
- [ ] `created_date` shows as **Date** type (calendar icon in column header)
- [ ] `created_hour` shows values 0–23
- [ ] `created_dow` shows full day names ("Monday", "Tuesday"…)
- [ ] `created_week` shows values like `2025-W36`, `2025-W37`
- [ ] `created_dow` is sorted by `created_dow_num` (Column tools → Sort by column)
- [ ] No red error banners in Power Query Editor
- [ ] Row count: tickets = 1,200

---

## Next Step → [Step 2: Build the Data Model](Step-2-DataModel.md)
