# Step 1 — Connect Your Data in Power BI (Power Query)

> **Goal:** Load all 5 tables from your CSV files into Power BI Desktop and apply correct data types.
> **Time:** ~15 minutes

---

## Option A — Connect via CSV Files (Recommended for this project)

This is the simplest method. Your 5 source CSVs map directly to Power BI tables.

### In Power BI Desktop:
1. Click **Home → Get Data → Text/CSV**
2. Load each file one at a time:

| File | Power BI Table Name |
|---|---|
| `tickets.csv` | `tickets` |
| `agents.csv` | `agents` |
| `customers.csv` | `customers` |
| `sla_logs.csv` | `sla_logs` |
| `escalation_reasons.csv` | `escalation_reasons` |

3. After loading each file, click **Transform Data** to open Power Query Editor

---

## Option B — Connect via SQLite (`opsSLA.db`)

Power BI does not have a native SQLite connector. Use this workaround:

1. Install the **SQLite ODBC driver**: https://www.ch-werner.de/sqliteodbc/
2. In Power BI: **Get Data → ODBC**
3. Select your SQLite DSN and pick all 5 tables

Alternatively, export tables to CSV from Python first:
```python
import sqlite3, pandas as pd
conn = sqlite3.connect('opsSLA.db')
for table in ['tickets','agents','customers','sla_logs','escalation_reasons']:
    pd.read_sql(f'SELECT * FROM {table}', conn).to_csv(f'data/{table}.csv', index=False)
```

---

## Power Query — Column Type Fixes

Paste this M code into **Advanced Editor** for the `tickets` table after loading:

```m
let
    Source = Csv.Document(
        File.Contents("C:\\path\\to\\data\\tickets.csv"),
        [Delimiter=",", Columns=20, Encoding=65001, QuoteStyle=QuoteStyle.None]
    ),
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    ChangedTypes = Table.TransformColumnTypes(PromotedHeaders, {
        {"ticket_id",              Int64.Type},
        {"created_at",             type datetime},
        {"customer_id",            Int64.Type},
        {"agent_id",               Int64.Type},
        {"escalation_reason_id",   Int64.Type},
        {"resolution_time_mins",   Int64.Type},
        {"resolution_time_hours",  type number},
        {"csat_score",             Int64.Type},
        {"escalation_flag",        Int64.Type},
        {"sla_breached_flag",       Int64.Type},
        {"repeat_contact_flag",    Int64.Type},
        {"severity_score",         Int64.Type}
    }),
    AddedWeekNum = Table.AddColumn(ChangedTypes, "iso_week",
        each "W" & Text.PadStart(Text.From(Date.WeekOfYear([created_at])), 2, "0"),
        type text
    ),
    AddedHour = Table.AddColumn(AddedWeekNum, "created_hour",
        each Time.Hour(DateTime.Time([created_at])),
        Int64.Type
    ),
    AddedDOW = Table.AddColumn(AddedHour, "day_of_week",
        each Date.DayOfWeekName(DateTime.Date([created_at])),
        type text
    ),
    AddedDate = Table.AddColumn(AddedDOW, "created_date",
        each DateTime.Date([created_at]),
        type date
    )
in
    AddedDate
```

### `agents` table type fixes:
```m
Table.TransformColumnTypes(Source, {
    {"agent_id",           Int64.Type},
    {"experience_months",  Int64.Type}
})
```

### `customers` table type fixes:
```m
Table.TransformColumnTypes(Source, {
    {"customer_id",     Int64.Type},
    {"tenure_months",   Int64.Type},
    {"risk_flag",       Int64.Type}
})
```

### `sla_logs` table type fixes:
```m
Table.TransformColumnTypes(Source, {
    {"ticket_id",               Int64.Type},
    {"sla_target_mins",         Int64.Type},
    {"actual_resolution_mins",  Int64.Type},
    {"sla_breached_flag",       Int64.Type}
})
```

---

## Verification Checklist

- [ ] All 5 tables loaded and visible in the **Data** pane
- [ ] `created_at` in `tickets` shows as **datetime** (not text)
- [ ] `escalation_flag`, `sla_breached_flag`, `csat_score` show as **whole number**
- [ ] No red error banners in Power Query Editor
- [ ] Row counts: tickets ~1200 · agents ~100 · customers ~500

---

## Next Step → [Step 2: Build the Data Model](Step-2-DataModel.md)
