# Data Ingestion — `data_ingestion.ipynb`

> **Project:** Operational Escalation, SLA & CSAT Analysis
> **Database:** SQLite (`opsSLA.db`) via SQLAlchemy
> **Author:** [@deegpt](https://github.com/deegpt)
> **Python:** 3.12 · Libraries: `pandas`, `sqlalchemy`, `logging`, `os`, `time`

---

## What This Notebook Does

`data_ingestion.ipynb` is the **entry point of the entire analytics pipeline**. It reads every raw `.csv` file from the `data/` folder and loads each one into a corresponding SQLite database table using a two-function script pattern. Every step is timed and logged to a persistent log file so the pipeline is fully auditable.

Once all CSVs are loaded, all downstream notebooks — EDA, escalation analysis, SLA tracking, and CSAT scoring — query directly from `opsSLA.db` instead of re-reading raw files. This separation of ingestion from analysis is a core data engineering best practice.

---

## Folder Structure

```
Data Ingestion/
├── data_ingestion.ipynb     ← This notebook (ingestion script)
├── README.md                ← You are here
data/
├── tickets.csv
├── agents.csv
├── customers.csv
├── sla_logs.csv
└── escalation_reasons.csv
logs/
└── ingestion_db.log         ← Auto-created on first run
opsSLA.db                    ← SQLite database (auto-created)
```

---

## How the Code Works

### Step 1 — Imports and Logging Setup

```python
import pandas as pd
import os
from sqlalchemy import create_engine
import logging
import time

logging.basicConfig(
    filename = 'logs/ingestion_db.log',
    level    = logging.DEBUG,
    format   = '%(asctime)s - %(levelname)s - %(message)s',
    filemode = 'a'           # append — never overwrites previous runs
)
```

`logging.basicConfig` wires up a file-based logger **before any data moves**. Using `filemode='a'` (append) means every run adds to the same log file — giving you a full history of every ingestion across time. The `%(asctime)s` format stamp means every log line is timestamped to the second.

| Log Level | When it fires |
|---|---|
| `logging.INFO` | Successful file ingestion + completion message |
| `logging.WARNING` | *(reserved)* — can be raised for unexpected column counts, etc. |
| `logging.ERROR` | *(reserved)* — can be raised on file read or DB write failure |
| `logging.DEBUG` | Captures all levels including verbose debug output |

---

### Step 2 — Database Connection

```python
engine = create_engine('sqlite:///opsSLA.db')
```

SQLAlchemy's `create_engine` creates (or connects to) a SQLite database file called `opsSLA.db` in the project root. SQLite requires no server, no credentials, and no installation — making it ideal for local analytical projects. Swapping to PostgreSQL or SQL Server later only requires changing this one connection string.

---

### Step 3 — `ingest_db()` Function

```python
def ingest_db(df, table_name, engine):
    '''This function will ingest the dataframe into database table'''
    df.to_sql(table_name, con=engine, if_exists='replace', index=False)
```

This function wraps pandas' `to_sql` with two important settings:

- **`if_exists='replace'`** — drops and recreates the table on every run, so re-running the notebook after fixing source data always produces a clean state
- **`index=False`** — prevents pandas from writing its integer row index as a spurious extra column in the database

The function is kept intentionally minimal so it can be extended later — e.g. adding `try/except` blocks, row count validation, or schema enforcement.

---

### Step 4 — `load_raw_data()` Function

```python
def load_raw_data():
    '''This function will load the CSVs as dataframe and ingest into db'''
    start = time.time()
    for file in os.listdir('data'):
        if '.csv' in file:
            df = pd.read_csv('data/' + file)
            logging.info(f'Ingesting {file} in db!')
            ingest_db(df, file[:-4], engine)
    end = time.time()
    total_time = (end - start) / 60
    logging.info('---------------------Ingestion Complete!!!-------------------------')
    logging.info(f'Total time taken: {total_time} minutes')
```

- `os.listdir('data')` dynamically discovers all files — **no hardcoded filenames**. Add a new CSV to `data/` and it is automatically picked up on the next run
- `file[:-4]` strips the `.csv` extension to derive the table name (e.g. `tickets.csv` → table `tickets`)
- `time.time()` wraps the entire loop so total pipeline duration is logged — useful for monitoring performance as data grows

---

### Step 5 — `if __name__ == '__main__'` Guard

```python
if __name__ == '__main__':
    load_raw_data()
```

This guard ensures `load_raw_data()` only executes when the file is **run directly** — not when it is imported as a module by another script. This is a Python scripting best practice that makes the notebook safe to convert to a `.py` file and schedule without side effects.

---

## Why Scripts + Logging? (The Design Rationale)

> *"If the data is coming in CSV from any server and we need to store it continuously in the database, **scripts can be used and scheduled at the required duration**."*

Notebooks are excellent for exploration, but production data pipelines need:

| Requirement | How this script addresses it |
|---|---|
| **Repeatability** | `if_exists='replace'` ensures every run produces an identical DB state |
| **Auditability** | `logging` writes a timestamped record of every file processed |
| **Schedulability** | `if __name__ == '__main__'` guard makes it safe to run as a `.py` via `cron`, Windows Task Scheduler, or Airflow |
| **Scalability** | Dynamic `os.listdir` loop means new tables require zero code changes |
| **Debuggability** | `logging.DEBUG` level captures everything — errors can be traced by timestamp even days later |

---

## Sample Log Output (`logs/ingestion_db.log`)

```
2025-10-01 09:14:02,311 - INFO - Ingesting tickets.csv in db!
2025-10-01 09:14:02,847 - INFO - Ingesting agents.csv in db!
2025-10-01 09:14:02,951 - INFO - Ingesting customers.csv in db!
2025-10-01 09:14:03,012 - INFO - Ingesting sla_logs.csv in db!
2025-10-01 09:14:03,089 - INFO - Ingesting escalation_reasons.csv in db!
2025-10-01 09:14:03,101 - INFO - -----------Ingestion Complete!!!-----------
2025-10-01 09:14:03,101 - INFO - Total time taken: 0.013 minutes
```

---

## How to Run

```bash
# Option 1 — Run in Jupyter
jupyter notebook "Data Ingestion/data_ingestion.ipynb"

# Option 2 — Convert and run as a plain Python script
jupyter nbconvert --to script "Data Ingestion/data_ingestion.ipynb"
python "Data Ingestion/data_ingestion.py"

# Option 3 — Schedule with cron (Linux/macOS) every day at 6 AM
0 6 * * * /usr/bin/python3 /path/to/data_ingestion.py
```

> **Prerequisite:** Create a `logs/` folder in the project root before first run, or add `os.makedirs('logs', exist_ok=True)` at the top of the script.

---

## Suggested Improvements

- Wrap `pd.read_csv` and `ingest_db` in `try/except` blocks and use `logging.error()` to capture failures without crashing the loop
- Add row count validation: log a warning if a CSV loads 0 rows
- Replace `if_exists='replace'` with `'append'` + deduplication logic for incremental loads
- Add a `logging.warning` if ingestion time exceeds a threshold (e.g. > 2 minutes)
