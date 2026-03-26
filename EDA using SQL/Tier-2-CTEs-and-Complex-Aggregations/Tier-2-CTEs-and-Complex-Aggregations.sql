-- ============================================================
-- FILE    : Tier-2-CTEs-and-Complex-Aggregations.sql
-- PROJECT : Operational Escalation, SLA & CSAT Analysis
-- DATABASE: SQL Server (OpsSLA)
-- AUTHOR  : github.com/deegpt
-- UPDATED : 2026-03-27
--
-- PURPOSE : Demonstrate multi-step Common Table Expressions (CTEs)
--           combined with conditional aggregation, NTILE percentile
--           banding, and a multi-stage failure funnel.
--
--   Q3 — CSAT Percentile Banding per Issue Category
--        Uses: NTILE(4), PERCENT_RANK(), DENSE_RANK(),
--              window aggregates (SUM/AVG OVER PARTITION BY)
--        JOIN : tickets → escalation_reasons (LEFT JOIN)
--        Goal : Identify the bottom-quartile CSAT tickets per
--               issue type and surface co-occurring failure signals.
--
--   Q4 — Escalation Funnel by Severity + Tier
--        Uses: CASE bucketing, chained CTEs, conditional SUM
--        JOIN : tickets → agents → sla_logs
--        Goal : Build a 4-stage failure funnel
--               (escalated → SLA breached → both → triple failure)
--               sliced by resolution-time severity band and tier.
--
--   Q5 — First Contact Resolution (FCR) Rate by Hour Bucket
--        Uses: DATEPART, CASE shift buckets, RANK() OVER PARTITION
--        JOIN : tickets → customers
--        Goal : Compare FCR rates across 4 day-shift buckets and
--               customer segments to expose where repeat contacts
--               cluster.
--
-- TABLES  : tickets, agents, customers, sla_logs, escalation_reasons
-- ============================================================

-- ============================================================
-- SAMPLE OUTPUT — Q3 (first 4 rows, bottom-quartile CSAT)
-- ============================================================
-- issue_category | ticket_id | csat_score | csat_percent_rank | resolution_time_mins | escalation_reason     | category_bottom_q_count
-- ---------------+-----------+------------+-------------------+----------------------+-----------------------+------------------------
-- ACCOUNTS       | 9036      | 1          | 0.0000            | 338                  | Process failure       | 58
-- ACCOUNTS       | 9117      | 1          | 0.0000            | 424                  | NULL                  | 58
-- CARDS          | 9011      | 1          | 0.0000            | 249                  | Agent knowledge gap   | 61
-- COMPLIANCE     | 9010      | 1          | 0.0000            | 214                  | Agent knowledge gap   | 52
-- ============================================================

-- ============================================================
-- SAMPLE OUTPUT — Q4 (first 4 rows, ordered by severity/tier)
-- ============================================================
-- severity_band   | agent_tier | total_tickets | esc_rate_pct | sla_breach_pct | combined_failure_pct | avg_csat
-- ----------------+------------+---------------+--------------+----------------+----------------------+---------
-- LOW (<=2h)      | L1         | 142           | 22.5         | 14.1           | 7.0                  | 3.18
-- LOW (<=2h)      | L2         | 68            | 19.1         | 11.8           | 5.9                  | 3.31
-- MEDIUM (2-6h)   | L1         | 198           | 27.3         | 38.4           | 15.2                 | 2.97
-- MEDIUM (2-6h)   | L2         | 89            | 21.3         | 35.9           | 11.2                 | 3.10
-- ============================================================

-- ============================================================
-- SAMPLE OUTPUT — Q5 (first 4 rows, ordered by shift/segment)
-- ============================================================
-- shift_bucket          | customer_segment | fcr_rate_pct | avg_csat | fcr_rank_in_segment
-- ----------------------+------------------+--------------+----------+--------------------
-- 1_Night (00-05)       | Metal            | 82.4         | 3.41     | 1
-- 1_Night (00-05)       | Plus             | 79.2         | 3.28     | 2
-- 2_Morning (06-11)     | Standard         | 71.3         | 3.05     | 3
-- 3_Afternoon (12-17)   | Premium          | 68.9         | 2.91     | 4
-- ============================================================

-- ====================================================================================================
-- Q3 — CSAT Percentile Banding per Issue Category
-- "Which tickets fall in the bottom 25th percentile of CSAT for each
--  issue type — and what is their avg resolution time?"
-- ====================================================================================================

WITH csat_banded AS (
    SELECT
        t.ticket_id, t.issue_category, t.csat_score,
        t.resolution_time_mins, t.escalation_flag,
        t.escalation_reason_id, t.repeat_contact_flag, t.country,
        NTILE(4) OVER (
            PARTITION BY t.issue_category
            ORDER BY t.csat_score ASC
        )                                               AS csat_quartile,
        ROUND(PERCENT_RANK() OVER (
            PARTITION BY t.issue_category
            ORDER BY t.csat_score ASC
        ), 4)                                           AS csat_percent_rank,
        DENSE_RANK() OVER (
            ORDER BY t.csat_score ASC
        )                                               AS overall_csat_rank
    FROM tickets AS t
),
bottom_quartile_enriched AS (
    SELECT
        b.ticket_id, b.issue_category, b.csat_score,
        b.csat_quartile, b.csat_percent_rank,
        b.resolution_time_mins, b.escalation_flag,
        b.repeat_contact_flag, b.country,
        er.reason_category                              AS escalation_reason,
        er.description                                  AS escalation_detail
    FROM csat_banded AS b
    LEFT JOIN escalation_reasons AS er
        ON b.escalation_reason_id = er.escalation_reason_id
    WHERE b.csat_quartile = 1
)
SELECT
    issue_category, ticket_id, csat_score, csat_percent_rank,
    resolution_time_mins, escalation_flag,
    escalation_reason, escalation_detail,
    repeat_contact_flag, country,
    COUNT(*)              OVER (PARTITION BY issue_category) AS category_bottom_q_count,
    AVG(resolution_time_mins) OVER (PARTITION BY issue_category) AS avg_res_mins_bottom_q,
    SUM(escalation_flag)  OVER (PARTITION BY issue_category) AS escalations_in_bottom_q,
    SUM(repeat_contact_flag) OVER (PARTITION BY issue_category) AS repeats_in_bottom_q
FROM bottom_quartile_enriched
ORDER BY issue_category, csat_score ASC;
GO

-- ====================================================================================================
-- Q4 — Escalation Funnel by Severity + Tier
-- "What share of tickets at each severity level end up escalated,
--  then SLA-breached, then repeat-contacted?"
-- ====================================================================================================

-- NOTE: No severity_score column in this dataset.
-- resolution_time_mins bucketed into 4 severity tiers as proxy.

WITH severity_tagged AS (
    SELECT
        t.ticket_id, t.issue_category, t.escalation_flag,
        t.escalation_reason_id, t.repeat_contact_flag,
        t.csat_score, t.resolution_time_mins,
        a.agent_id, a.agent_tier, a.region,
        CASE
            WHEN t.resolution_time_mins <= 120  THEN 'LOW      (<=2h)'
            WHEN t.resolution_time_mins <= 360  THEN 'MEDIUM   (2-6h)'
            WHEN t.resolution_time_mins <= 720  THEN 'HIGH     (6-12h)'
            ELSE                                     'CRITICAL (>12h)'
        END                                         AS severity_band,
        CASE
            WHEN t.resolution_time_mins <= 120  THEN 1
            WHEN t.resolution_time_mins <= 360  THEN 2
            WHEN t.resolution_time_mins <= 720  THEN 3
            ELSE                                     4
        END                                         AS severity_order
    FROM tickets AS t
    INNER JOIN agents AS a ON t.agent_id = a.agent_id
),
funnel_with_sla AS (
    SELECT
        st.ticket_id, st.issue_category, st.escalation_flag,
        st.escalation_reason_id, st.repeat_contact_flag,
        st.csat_score, st.agent_id, st.agent_tier, st.region,
        st.severity_band, st.severity_order,
        sl.sla_breached_flag,
        sl.breach_reason
    FROM severity_tagged AS st
    INNER JOIN sla_logs AS sl ON st.ticket_id = sl.ticket_id
),
funnel_aggregated AS (
    SELECT
        severity_band, severity_order, agent_tier,
        COUNT(*)                                            AS total_tickets,
        SUM(escalation_flag)                               AS stage1_escalated,
        SUM(sla_breached_flag)                             AS stage2_sla_breached,
        SUM(CASE WHEN escalation_flag = 1
                  AND sla_breached_flag = 1
                  THEN 1 ELSE 0 END)                       AS stage3_both_failed,
        SUM(repeat_contact_flag)                           AS stage4_repeat_contact,
        SUM(CASE WHEN escalation_flag = 1
                  AND sla_breached_flag = 1
                  AND repeat_contact_flag = 1
                  THEN 1 ELSE 0 END)                       AS triple_failure_count,
        ROUND(AVG(CAST(csat_score AS FLOAT)), 2)           AS avg_csat
    FROM funnel_with_sla
    GROUP BY severity_band, severity_order, agent_tier
)
SELECT
    severity_band, agent_tier, total_tickets,
    stage1_escalated,
    ROUND(stage1_escalated    * 100.0 / NULLIF(total_tickets, 0), 1) AS esc_rate_pct,
    stage2_sla_breached,
    ROUND(stage2_sla_breached * 100.0 / NULLIF(total_tickets, 0), 1) AS sla_breach_pct,
    stage3_both_failed,
    ROUND(stage3_both_failed  * 100.0 / NULLIF(total_tickets, 0), 1) AS combined_failure_pct,
    triple_failure_count,
    ROUND(triple_failure_count * 100.0 / NULLIF(total_tickets, 0), 1) AS triple_failure_pct,
    avg_csat
FROM funnel_aggregated
ORDER BY severity_order, agent_tier;
GO

-- ====================================================================================================
-- Q5 — First Contact Resolution (FCR) Rate by Hour Bucket
-- "Is FCR worse during peak hours? Bucket the day into 4 shifts
--  and compare across customer segments."
-- ====================================================================================================

WITH hour_bucketed AS (
    SELECT
        t.ticket_id, t.repeat_contact_flag, t.csat_score,
        t.resolution_time_mins, t.issue_category,
        c.customer_segment,
        DATEPART(HOUR, t.created_at)                    AS created_hour,
        CASE
            WHEN DATEPART(HOUR, t.created_at) BETWEEN  0 AND  5
                 THEN '1_Night     (00-05)'
            WHEN DATEPART(HOUR, t.created_at) BETWEEN  6 AND 11
                 THEN '2_Morning   (06-11)'
            WHEN DATEPART(HOUR, t.created_at) BETWEEN 12 AND 17
                 THEN '3_Afternoon (12-17)'
            ELSE      '4_Evening   (18-23)'
        END                                             AS shift_bucket,
        CASE WHEN t.repeat_contact_flag = 0 THEN 1 ELSE 0 END
                                                        AS fcr_achieved
    FROM tickets AS t
    INNER JOIN customers AS c ON t.customer_id = c.customer_id
),
shift_summary AS (
    SELECT
        shift_bucket, customer_segment,
        COUNT(*)                                        AS total_tickets,
        SUM(fcr_achieved)                               AS fcr_count,
        ROUND(SUM(fcr_achieved) * 100.0 / NULLIF(COUNT(*), 0), 1)
                                                        AS fcr_rate_pct,
        ROUND(AVG(CAST(csat_score AS FLOAT)), 2)        AS avg_csat,
        ROUND(AVG(CAST(resolution_time_mins AS FLOAT)), 0)
                                                        AS avg_res_mins
    FROM hour_bucketed
    GROUP BY shift_bucket, customer_segment
)
SELECT
    shift_bucket, customer_segment, total_tickets,
    fcr_count, fcr_rate_pct, avg_csat, avg_res_mins,
    RANK() OVER (
        PARTITION BY customer_segment
        ORDER BY fcr_rate_pct DESC
    )                                                   AS fcr_rank_in_segment
FROM shift_summary
ORDER BY shift_bucket, customer_segment;
GO
