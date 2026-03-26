# Step 4 — Dashboard Page Layout & Visual Specs

> **Goal:** Build all 5 dashboard pages visual by visual, using the exact measures from Step 3.
> **Time:** ~60–90 minutes total

---

## Global Settings (Apply Once)

1. **Canvas size:** Go to **View → Page view → Fit to page**. Set canvas to **1440 × 900 px** (16:9 widescreen)
2. **Theme:** Go to **View → Themes → Browse** and apply a dark or professional theme, OR use the custom colours below:
   - Primary Blue: `#4C9BE8`
   - Alert Red: `#E84C4C`
   - Success Green: `#4CE88A`
   - Warning Orange: `#E8A14C`
   - Background: `#1E1E2E` (dark) or `#F5F5F5` (light)
3. **Slicer panel:** Every page shares the same 3 slicers — add them to all pages:
   - Date range slicer → `DateTable[Date]` (set style to **Between**)
   - Agent Tier slicer → `agents[agent_tier]` (set style to **Dropdown**)
   - Customer Segment slicer → `customers[customer_segment]` (set style to **Dropdown**)

---

## Page 1 — Executive Overview

> *"Monday-morning view for ops managers — what happened last week at a glance?"*

### Row 1 — KPI Cards (4 across top, equal width)

| Card # | Measure | Label | Colour rule |
|---|---|---|---|
| 1 | `[Total Tickets]` | Total Tickets | Neutral |
| 2 | `[Escalation Rate %]` | Escalation Rate | Red if > 30% |
| 3 | `[SLA Breach Rate %]` | SLA Breach Rate | Red if > 40% |
| 4 | `[Avg CSAT]` | Avg CSAT | Red if < 3.0 |

**How to add KPI card:**
1. Insert → Card visual
2. Drag the measure into the **Fields** well
3. Format → Callout value → set font size 36
4. Format → Category label → rename to the label above

### Row 2 — Trend Line Chart (full width)

- **Visual type:** Line chart
- **X-axis:** `DateTable[ISO Week]`
- **Y-axis:** `[SLA Breach Rate %]` AND `[Escalation Rate %]` (two lines)
- **Secondary line:** `[SLA Breach Rate (4Wk Rolling)]` as a dotted reference line
- **Title:** "Weekly SLA Breach & Escalation Rate (Sep–Oct 2025)"
- **Format:** Enable data labels · Show markers

### Row 3 — Two charts side by side

**Left — Bar chart: Ticket Volume by Issue Category**
- Visual type: Clustered bar chart
- Y-axis: `tickets[issue_category]`
- X-axis: `[Total Tickets]`
- Colour: Single colour `#4C9BE8`
- Data labels: On
- Sort: Descending by ticket count

**Right — Donut chart: Escalation Split**
- Visual type: Donut chart
- Legend: `tickets[escalation_flag]` (rename 0 = Not Escalated, 1 = Escalated)
- Values: `[Total Tickets]`
- Colours: `#4CE88A` for 0, `#E84C4C` for 1

---

## Page 2 — Escalation Deep Dive

> *"Which agents, categories, and days are driving escalations?"*

### Visual 1 — Bar chart: Escalation Rate by Agent Tier
- Visual type: Clustered bar
- Y-axis: `agents[agent_tier]`
- X-axis: `[Escalation Rate %]`
- Colours: `#4C9BE8` (L1), `#E8A14C` (L2), `#4CE88A` (L3)
- Data labels: On (format as %)
- Sort: Descending

### Visual 2 — Bar chart: Top Escalation Reasons
- Visual type: Horizontal bar
- Y-axis: `escalation_reasons[reason_category]`
- X-axis: `[Total Escalations]`
- Colour: `#E84C4C`
- Filter: Top N = 10 (by `[Total Escalations]`)
- Sort: Descending

### Visual 3 — Matrix: Escalation Rate by Category × Tier
- Visual type: Matrix table
- Rows: `tickets[issue_category]`
- Columns: `agents[agent_tier]`
- Values: `[Escalation Rate %]`
- Conditional formatting on values:
  - Red background if > 35%
  - Orange if 25–35%
  - Green if < 25%

### Visual 4 — Bar chart: Escalation Rate by Day of Week
- Visual type: Clustered column chart
- X-axis: `tickets[day_of_week]`
- Y-axis: `[Escalation Rate %]`
- Sort: Mon → Sun (add sort column with `WEEKDAY()` value 1–7)
- Colour: `#9B4CE8`
- Data labels: On

### Visual 5 — Scatter plot: Agent Esc Rate vs CSAT
- Visual type: Scatter chart
- X-axis: `[Escalation Rate %]`
- Y-axis: `[Avg CSAT]`
- Details: `agents[agent_id]`
- Legend: `agents[agent_tier]`
- Title: "Agents: Higher Escalation Rate → Lower CSAT?"
- This will show each agent as a dot — L1 agents should cluster top-right (high esc, low CSAT)

---

## Page 3 — SLA Compliance

> *"Where and when is SLA being breached, and is it improving?"*

### Visual 1 — KPI cards (3 across top)

| Measure | Label |
|---|---|
| `[SLA Breach Rate %]` | Overall Breach Rate |
| `[SLA Breach WoW Label]` | WoW Change |
| `[SLA Breach Rate (4Wk Rolling)]` | 4-Week Rolling Avg |

### Visual 2 — Line chart: Weekly SLA Breach Rate Trend
- X-axis: `DateTable[ISO Week]`
- Y-axis: `[SLA Breach Rate %]`
- Reference line: Average breach rate (constant line)
- Enable data labels and markers
- Fill area under line with 10% opacity blue

### Visual 3 — Bar chart: SLA Breach Rate by Agent Tier
- Y-axis: `agents[agent_tier]`
- X-axis: `[SLA Breach Rate %]`
- Colours: Match Page 2 tier colours
- Data labels: On

### Visual 4 — Bar chart: SLA Breach Rate by Region
- Y-axis: `agents[region]`
- X-axis: `[SLA Breach Rate %]`
- Colour: `#4CE8D5`

### Visual 5 — Bar chart: Breach Reasons
- Y-axis: `sla_logs[breach_reason]`
- X-axis: `[Total SLA Breaches]`
- Colour: `#E84C4C`
- This will show: High backlog vs Agent capacity vs None

### Visual 6 — Heatmap: Breach Rate by Hour × Day
- Visual type: **Matrix table** (styled as heatmap)
- Rows: `tickets[day_of_week]`
- Columns: `tickets[created_hour]`
- Values: `[SLA Breach Rate %]`
- Conditional formatting: Red (high) → Green (low) colour scale
- This reveals the exact hour-day combinations where breaches cluster

---

## Page 4 — CSAT & Agent Scorecard

> *"Which agents are performing best? Where is customer satisfaction lowest?"*

### Visual 1 — Bar chart: Avg CSAT by Issue Category
- Visual type: Horizontal bar
- Y-axis: `tickets[issue_category]`
- X-axis: `[Avg CSAT]`
- Conditional colours: Red if < 3.0, Orange if 3.0–3.5, Green if > 3.5
- Reference line at 3.5 (avg)
- Sort: Ascending (worst CSAT at top)

### Visual 2 — Column chart: CSAT Distribution (1–5)
- Visual type: Clustered column
- X-axis: `tickets[csat_score]` (1, 2, 3, 4, 5)
- Y-axis: `[Total Tickets]`
- Colours: Red for 1–2, Orange for 3, Green for 4–5
- Data labels: Show % of total

### Visual 3 — KPI cards (3 across)

| Measure | Label |
|---|---|
| `[Avg CSAT (Escalated)]` | CSAT when Escalated |
| `[Avg CSAT (SLA Breached)]` | CSAT when SLA Breached |
| `[CSAT Impact of SLA Breach]` | CSAT Gap: Breach vs Compliant |

### Visual 4 — Agent Scorecard Matrix (star of the page)
- Visual type: **Matrix table**
- Rows: `agents[agent_id]` (grouped by `agents[agent_tier]`)
- Values: `[Total Tickets]`, `[Escalation Rate %]`, `[SLA Breach Rate %]`, `[Avg CSAT]`, `[Agent Health Score]`
- Conditional formatting on `[Agent Health Score]`:
  - Green if > 70
  - Orange if 50–70
  - Red if < 50
- Sort by `[Agent Health Score]` descending
- This is your **talent management view** — instantly identifies underperforming L1 agents

### Visual 5 — Bar: Avg CSAT by Customer Segment
- Y-axis: `customers[customer_segment]`
- X-axis: `[Avg CSAT]`
- Colour: `#4C9BE8`

---

## Page 5 — High-Risk Triage Table

> *"Daily list of at-risk customers who hit SLA breach — for the support ops team to action today."*

### Visual 1 — KPI cards (3 across)

| Measure | Label |
|---|---|
| `[High Risk Tickets]` | High-Risk Tickets |
| `[High Risk + SLA Breach]` | Breached & High Risk |
| `[High Risk SLA Breach Rate %]` | High Risk Breach Rate |

### Visual 2 — Table: Triage List
- Visual type: **Table** (not matrix)
- Columns in order:
  1. `tickets[ticket_id]`
  2. `tickets[created_at]`
  3. `tickets[issue_category]`
  4. `customers[customer_segment]`
  5. `customers[risk_flag]`
  6. `sla_logs[sla_breached_flag]`
  7. `escalation_reasons[reason_category]`
  8. `sla_logs[breach_reason]`
  9. `tickets[csat_score]`
  10. `[Avg Resolution (mins)]`
- Filter: `customers[risk_flag] = 1` AND `sla_logs[sla_breached_flag] = 1`
- Sort: `tickets[created_at]` descending (most recent first)
- Conditional format: `csat_score` → red if 1 or 2

### Visual 3 — Bar: High-Risk Breaches by Segment
- Y-axis: `customers[customer_segment]`
- X-axis: `[High Risk + SLA Breach]`
- Colour: `#E84C4C`

### Visual 4 — Bar: High-Risk Breaches by Issue Category
- Y-axis: `tickets[issue_category]`
- X-axis: `[High Risk SLA Breach Rate %]`
- Colour: `#E8A14C`

---

## Final Checklist Before Publishing

- [ ] All 5 pages have the 3 global slicers (Date, Tier, Segment)
- [ ] All KPI cards show correct values matching your Python analysis
- [ ] Agent Scorecard matrix is sortable by Health Score
- [ ] Triage table is filtered to risk_flag=1 + sla_breached=1
- [ ] Every chart has a descriptive title and labelled axes
- [ ] Colour coding is consistent (Red = bad, Green = good) across all pages
- [ ] Report saved as `Operational_Escalation_SLA_CSAT_Dashboard.pbix`

---

## Publishing to Power BI Service (Optional)

1. **Home → Publish** in Power BI Desktop
2. Sign in with your Microsoft account (free tier works)
3. Select **My Workspace**
4. Once published, share the link on your GitHub repo README as a badge

```markdown
[![Power BI Dashboard](https://img.shields.io/badge/Power%20BI-Dashboard-yellow?logo=powerbi)](YOUR_PUBLISH_LINK_HERE)
```
