-- ============================================================
-- FILE    : Tier-3-Views.sql
-- PROJECT : Operational Escalation, SLA & CSAT Analysis
-- DATABASE: SQL Server (OpsSLA)
-- AUTHOR  : github.com/deegpt
-- UPDATED : 2026-03-27
--
-- PURPOSE : Create three reusable SQL Server VIEWs that act as
--           pre-built analytical lenses over the raw tables.
--           Views hide JOIN complexity and let dashboards, reports,
--           and ad-hoc queries read clean, pre-aggregated data.
--
--   V1 — vw_agent_performance_scorecard
--        Composite KPI view per agent: CSAT, escalation rate,
--        SLA breach rate, repeat rate, and a weighted health score.
--        JOIN: agents → tickets → sla_logs
--
--   V2 — vw_weekly_ops_summary
--        One row per ISO week summarising all operational KPIs.
--        JOIN: tickets → sla_logs
--
--   V3 — vw_high_risk_customer_tickets
--        Every SLA-breached ticket belonging to a risk_flag=1
--        customer, enriched with escalation reason detail.
--        JOIN: tickets → customers → sla_logs → escalation_reasons
--
-- USAGE   : SELECT * FROM vw_agent_performance_scorecard
--           ORDER BY agent_health_score DESC;
-- ============================================================

-- ============================================================
-- SAMPLE OUTPUT — V1  vw_agent_performance_scorecard
-- ============================================================
-- agent_id | agent_tier | region | total_tickets | avg_csat | esc_rate_pct | sla_breach_pct | agent_health_score
-- ---------+------------+--------+---------------+----------+--------------+----------------+-------------------
-- 202      | L3         | APAC   | 14            | 3.79     | 14.3         | 21.4           | 77.4
-- 212      | L3         | EMEA   | 11            | 3.64     | 18.2         | 27.3           | 72.1
-- 263      | L2         | APAC   | 13            | 3.54     | 15.4         | 30.8           | 69.8
-- 283      | L1         | NA     | 16            | 3.25     | 25.0         | 37.5           | 61.3
-- ============================================================

-- ============================================================
-- SAMPLE OUTPUT — V2  vw_weekly_ops_summary
-- ============================================================
-- iso_week  | ticket_volume | active_agents | esc_rate_pct | sla_breach_pct | avg_csat
-- ----------+---------------+---------------+--------------+----------------+---------
-- 2025-W36  | 156           | 87            | 26.3         | 53.8           | 3.14
-- 2025-W37  | 180           | 91            | 24.4         | 47.2           | 3.21
-- 2025-W38  | 192           | 93            | 25.0         | 41.7           | 3.19
-- 2025-W39  | 168           | 88            | 27.4         | 38.1           | 3.08
-- ============================================================

-- ============================================================
-- SAMPLE OUTPUT — V3  vw_high_risk_customer_tickets
-- ============================================================
-- ticket_id | customer_id | customer_segment | risk_flag | sla_breached_flag | escalation_reason
-- ----------+-------------+------------------+-----------+-------------------+------------------
-- 9050      | 1050        | Premium          | 1         | 1                 | Agent capacity
-- 9069      | 1069        | Standard         | 1         | 1                 | High backlog
-- 9104      | 1104        | Plus             | 1         | 1                 | Manual review delay
-- 9136      | 1136        | Premium          | 1         | 1                 | Agent capacity
-- ============================================================

-- Drop in safe order before recreating
IF OBJECT_ID('vw_high_risk_customer_tickets', 'V') IS NOT NULL DROP VIEW vw_high_risk_customer_tickets;
IF OBJECT_ID('vw_weekly_ops_summary',          'V') IS NOT NULL DROP VIEW vw_weekly_ops_summary;
IF OBJECT_ID('vw_agent_performance_scorecard', 'V') IS NOT NULL DROP VIEW vw_agent_performance_scorecard;
GO

-- ============================================================
-- V1 — Agent Performance Scorecard
-- ============================================================
CREATE VIEW vw_agent_performance_scorecard AS
SELECT
    a.agent_id, a.agent_tier, a.region, a.experience_months,
    COUNT(t.ticket_id)                                          AS total_tickets,
    ROUND(AVG(CAST(t.csat_score          AS FLOAT)), 2)         AS avg_csat,
    ROUND(AVG(CAST(t.escalation_flag     AS FLOAT)) * 100, 1)   AS esc_rate_pct,
    ROUND(AVG(CAST(s.sla_breached_flag   AS FLOAT)) * 100, 1)   AS sla_breach_pct,
    ROUND(AVG(CAST(t.repeat_contact_flag AS FLOAT)) * 100, 1)   AS repeat_rate_pct,
    ROUND(AVG(CAST(t.resolution_time_mins AS FLOAT)), 0)        AS avg_res_mins,
    ROUND(
        (AVG(CAST(t.csat_score        AS FLOAT)) / 5.0) * 40
        + ((1 - AVG(CAST(t.escalation_flag   AS FLOAT)))  * 30)
        + ((1 - AVG(CAST(s.sla_breached_flag AS FLOAT)))  * 30)
    , 1)                                                        AS agent_health_score
FROM agents AS a
LEFT JOIN tickets  AS t ON a.agent_id  = t.agent_id
LEFT JOIN sla_logs AS s ON t.ticket_id = s.ticket_id
GROUP BY a.agent_id, a.agent_tier, a.region, a.experience_months;
GO

-- ============================================================
-- V2 — Weekly Operations Summary
-- ============================================================
CREATE VIEW vw_weekly_ops_summary AS
SELECT
    CAST(YEAR(t.created_at) AS VARCHAR) + '-W'
        + RIGHT('0' + CAST(DATEPART(ISO_WEEK, t.created_at) AS VARCHAR), 2)
                                                            AS iso_week,
    COUNT(t.ticket_id)                                      AS ticket_volume,
    COUNT(DISTINCT t.agent_id)                              AS active_agents,
    COUNT(DISTINCT t.customer_id)                           AS unique_customers,
    ROUND(AVG(CAST(t.escalation_flag     AS FLOAT)) * 100, 1) AS esc_rate_pct,
    ROUND(AVG(CAST(s.sla_breached_flag   AS FLOAT)) * 100, 1) AS sla_breach_pct,
    ROUND(AVG(CAST(t.repeat_contact_flag AS FLOAT)) * 100, 1) AS repeat_rate_pct,
    ROUND(AVG(CAST(t.csat_score          AS FLOAT)), 2)     AS avg_csat,
    ROUND(AVG(CAST(t.resolution_time_mins AS FLOAT)), 0)    AS avg_res_mins
FROM tickets AS t
INNER JOIN sla_logs AS s ON t.ticket_id = s.ticket_id
GROUP BY
    CAST(YEAR(t.created_at) AS VARCHAR) + '-W'
        + RIGHT('0' + CAST(DATEPART(ISO_WEEK, t.created_at) AS VARCHAR), 2);
GO

-- ============================================================
-- V3 — High-Risk Customer Tickets (SLA-breached + risk_flag=1)
-- ============================================================
CREATE VIEW vw_high_risk_customer_tickets AS
SELECT
    t.ticket_id, t.created_at, t.issue_category,
    t.escalation_flag, t.csat_score, t.repeat_contact_flag,
    c.customer_id, c.customer_segment, c.tenure_months, c.risk_flag,
    s.sla_breached_flag, s.breach_reason,
    er.reason_category  AS escalation_reason,
    er.description      AS escalation_detail
FROM tickets AS t
INNER JOIN customers AS c
    ON t.customer_id = c.customer_id
INNER JOIN sla_logs AS s
    ON t.ticket_id = s.ticket_id
LEFT JOIN escalation_reasons AS er
    ON t.escalation_reason_id = er.escalation_reason_id
WHERE c.risk_flag        = 1
  AND s.sla_breached_flag = 1;
GO
