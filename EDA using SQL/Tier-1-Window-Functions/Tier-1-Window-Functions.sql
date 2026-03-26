-- ============================================================
-- FILE    : Tier-1-Window-Functions.sql
-- PROJECT : Operational Escalation, SLA & CSAT Analysis
-- DATABASE: SQL Server (OpsSLA)
-- AUTHOR  : github.com/deegpt
-- UPDATED : 2026-03-27
--
-- PURPOSE : Demonstrate advanced SQL Window Functions applied to
--           a fintech support operations dataset (1,200 tickets,
--           Sep–Oct 2025).  Two analytical questions are answered:
--
--   Q1 — Agent Ranking by Escalation Rate Within Tier (WoW)
--        Uses: RANK(), LAG(), SUM() OVER(), NULLIF()
--        JOIN : tickets → agents
--        Goal : Surface which agents are consistently high
--               escalators within their tier and whether their
--               rank is improving or deteriorating week-on-week.
--
--   Q2 — SLA Breach Trend: Week-over-Week Change
--        Uses: LAG(), AVG() OVER (ROWS BETWEEN ...), DATEPART()
--        JOIN : tickets → sla_logs
--        Goal : Quantify by how much the breach rate improved
--               or worsened each week; smooth with a 4-week
--               rolling average to separate signal from noise.
--
-- TABLES  : tickets, agents, sla_logs
-- ============================================================

-- ============================================================
-- SAMPLE OUTPUT — Q1 (first 4 rows, ordered by tier/week/rank)
-- ============================================================
-- agent_tier | iso_week  | agent_id | esc_rate_pct | esc_rank_in_tier | rank_change_wow | rank_trend
-- -----------+-----------+----------+--------------+------------------+-----------------+---------------------
-- L1         | 2025-W36  | 257      | 50.00        | 1                | NULL            | — First week
-- L1         | 2025-W36  | 224      | 44.44        | 2                | NULL            | — First week
-- L1         | 2025-W37  | 257      | 55.56        | 1                | 0               | → No change
-- L1         | 2025-W37  | 220      | 50.00        | 2                | NULL            | — First week
-- ============================================================

-- ============================================================
-- SAMPLE OUTPUT — Q2 (first 4 rows, ordered by week)
-- ============================================================
-- iso_week  | breach_rate_pct | prev_week_breach_pct | wow_change_pct | rolling_4wk_avg_pct | trend_direction
-- ----------+-----------------+----------------------+----------------+---------------------+----------------
-- 2025-W36  | 53.85           | NULL                 | NULL           | 53.85               | — Baseline week
-- 2025-W37  | 47.22           | 53.85                | -6.63          | 50.54               | ▼ Improved
-- 2025-W38  | 41.67           | 47.22                | -5.55          | 47.58               | ▼ Improved
-- 2025-W39  | 38.10           | 41.67                | -3.57          | 45.21               | ▼ Improved
-- ============================================================

-- ====================================================================================================
-- Q1 — Agent Ranking by Escalation Rate Within Tier (Week-over-Week)
-- "Which agents within each tier consistently escalate the most,
--  and how does their rank change week-over-week?"
-- ====================================================================================================

WITH weekly_agent_stats AS (
    SELECT
        a.agent_id,
        a.agent_tier,
        a.region,
        CAST(YEAR(t.created_at) AS VARCHAR) + '-W'
            + RIGHT('0' + CAST(DATEPART(ISO_WEEK, t.created_at) AS VARCHAR), 2)
                                                        AS iso_week,
        DATEADD(DAY,
            1 - DATEPART(WEEKDAY, t.created_at + @@DATEFIRST - 2),
            CAST(t.created_at AS DATE))                 AS week_start_date,
        COUNT(t.ticket_id)                              AS total_tickets,
        SUM(t.escalation_flag)                          AS total_escalations
    FROM tickets AS t
    INNER JOIN agents AS a
        ON t.agent_id = a.agent_id
    GROUP BY
        a.agent_id, a.agent_tier, a.region,
        CAST(YEAR(t.created_at) AS VARCHAR) + '-W'
            + RIGHT('0' + CAST(DATEPART(ISO_WEEK, t.created_at) AS VARCHAR), 2),
        DATEADD(DAY,
            1 - DATEPART(WEEKDAY, t.created_at + @@DATEFIRST - 2),
            CAST(t.created_at AS DATE))
),
agent_weekly_ranked AS (
    SELECT
        agent_id, agent_tier, region, iso_week, week_start_date,
        total_tickets, total_escalations,
        ROUND(total_escalations * 100.0 / NULLIF(total_tickets, 0), 2)
                                                        AS esc_rate_pct,
        RANK() OVER (
            PARTITION BY agent_tier, iso_week
            ORDER BY total_escalations * 1.0 / NULLIF(total_tickets, 0) DESC
        )                                               AS esc_rank_in_tier,
        SUM(total_tickets) OVER (
            PARTITION BY agent_id
            ORDER BY week_start_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                               AS cumulative_tickets
    FROM weekly_agent_stats
),
agent_rank_movement AS (
    SELECT
        agent_id, agent_tier, region, iso_week, week_start_date,
        total_tickets, total_escalations, esc_rate_pct,
        esc_rank_in_tier, cumulative_tickets,
        LAG(esc_rank_in_tier) OVER (
            PARTITION BY agent_id ORDER BY week_start_date
        )                                               AS prev_week_rank,
        esc_rank_in_tier - LAG(esc_rank_in_tier) OVER (
            PARTITION BY agent_id ORDER BY week_start_date
        )                                               AS rank_change_wow,
        CASE
            WHEN esc_rank_in_tier <
                 LAG(esc_rank_in_tier) OVER (PARTITION BY agent_id ORDER BY week_start_date)
                 THEN '↑ Worse (more escalations)'
            WHEN esc_rank_in_tier >
                 LAG(esc_rank_in_tier) OVER (PARTITION BY agent_id ORDER BY week_start_date)
                 THEN '↓ Better (fewer escalations)'
            WHEN LAG(esc_rank_in_tier) OVER (PARTITION BY agent_id ORDER BY week_start_date)
                 IS NULL  THEN '— First week'
            ELSE               '→ No change'
        END                                             AS rank_trend
    FROM agent_weekly_ranked
)
SELECT
    agent_tier, iso_week, week_start_date, agent_id, region,
    total_tickets, total_escalations, esc_rate_pct,
    esc_rank_in_tier, prev_week_rank, rank_change_wow,
    rank_trend, cumulative_tickets
FROM agent_rank_movement
ORDER BY agent_tier, week_start_date, esc_rank_in_tier;
GO

-- ====================================================================================================
-- Q2 — SLA Breach Trend: Week-over-Week Change
-- "By how much did the SLA breach rate improve or worsen each week
--  compared to the previous week?"
-- ====================================================================================================

WITH weekly_breach_stats AS (
    SELECT
        CAST(YEAR(t.created_at) AS VARCHAR) + '-W'
            + RIGHT('0' + CAST(DATEPART(ISO_WEEK, t.created_at) AS VARCHAR), 2)
                                                        AS iso_week,
        DATEADD(DAY,
            2 - DATEPART(WEEKDAY, t.created_at),
            CAST(t.created_at AS DATE))                 AS week_start_date,
        COUNT(t.ticket_id)                              AS total_tickets,
        SUM(s.sla_breached_flag)                        AS total_breaches,
        ROUND(SUM(s.sla_breached_flag) * 100.0
              / NULLIF(COUNT(t.ticket_id), 0), 2)       AS breach_rate_pct,
        AVG(CASE WHEN s.sla_breached_flag = 1
                 THEN s.actual_resolution_mins - s.sla_target_mins
                 ELSE NULL END)                         AS avg_breach_overrun_mins,
        MAX(s.breach_reason)                            AS dominant_breach_reason
    FROM tickets AS t
    INNER JOIN sla_logs AS s
        ON t.ticket_id = s.ticket_id
    GROUP BY
        CAST(YEAR(t.created_at) AS VARCHAR) + '-W'
            + RIGHT('0' + CAST(DATEPART(ISO_WEEK, t.created_at) AS VARCHAR), 2),
        DATEADD(DAY, 2 - DATEPART(WEEKDAY, t.created_at), CAST(t.created_at AS DATE))
),
wow_comparison AS (
    SELECT
        iso_week, week_start_date, total_tickets, total_breaches,
        breach_rate_pct, avg_breach_overrun_mins, dominant_breach_reason,
        LAG(breach_rate_pct)  OVER (ORDER BY week_start_date)
                                                        AS prev_week_breach_pct,
        ROUND(breach_rate_pct -
              LAG(breach_rate_pct) OVER (ORDER BY week_start_date), 2)
                                                        AS wow_change_pct,
        ROUND(AVG(breach_rate_pct) OVER (
            ORDER BY week_start_date
            ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
        ), 2)                                           AS rolling_4wk_avg_pct,
        CASE
            WHEN breach_rate_pct >
                 LAG(breach_rate_pct) OVER (ORDER BY week_start_date)
                 THEN '▲ Worsened'
            WHEN breach_rate_pct <
                 LAG(breach_rate_pct) OVER (ORDER BY week_start_date)
                 THEN '▼ Improved'
            WHEN LAG(breach_rate_pct) OVER (ORDER BY week_start_date) IS NULL
                 THEN '— Baseline week'
            ELSE      '→ No change'
        END                                             AS trend_direction
    FROM weekly_breach_stats
)
SELECT
    iso_week, week_start_date, total_tickets, total_breaches,
    breach_rate_pct, prev_week_breach_pct, wow_change_pct,
    rolling_4wk_avg_pct, avg_breach_overrun_mins,
    dominant_breach_reason, trend_direction
FROM wow_comparison
ORDER BY week_start_date;
GO
