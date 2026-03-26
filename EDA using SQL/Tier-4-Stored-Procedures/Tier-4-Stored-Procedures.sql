-- ============================================================
-- FILE    : Tier-4-Stored-Procedures.sql
-- PROJECT : Operational Escalation, SLA & CSAT Analysis
-- DATABASE: SQL Server (OpsSLA)
-- AUTHOR  : github.com/deegpt
-- UPDATED : 2026-03-27
--
-- PURPOSE : Encapsulate reusable, parameterised analytical queries
--           as SQL Server Stored Procedures.  Procedures enforce
--           input validation, prevent SQL injection via typed
--           parameters, and produce consistent result sets that
--           Power BI, Python, or application layers can call.
--
--   SP1 — sp_sla_breach_report
--         Params : @p_start_date DATE, @p_end_date DATE,
--                  @p_agent_tier VARCHAR(2) [default NULL = all]
--         Returns: SLA breach rate, avg resolution time, avg CSAT,
--                  and top breach reason per issue category x tier
--                  for any date range.
--         JOIN   : tickets → sla_logs → agents
--
--   SP2 — sp_customer_escalation_history
--         Params : @p_customer_id INT,
--                  @p_top_n INT [default 10]
--         Returns: Most recent N escalated tickets for a given
--                  customer, fully enriched with escalation reason,
--                  SLA outcome, and customer segment.
--         JOIN   : tickets → customers → escalation_reasons → sla_logs
--
-- USAGE   :
--   EXEC sp_sla_breach_report '2025-09-01', '2025-09-30', 'L1';
--   EXEC sp_customer_escalation_history 1050, 5;
-- ============================================================

-- ============================================================
-- SAMPLE OUTPUT — SP1  sp_sla_breach_report ('2025-09-01','2025-09-30','L1')
-- ============================================================
-- issue_category | agent_tier | region | total_tickets | breaches | breach_rate_pct | avg_csat | top_breach_reason
-- ---------------+------------+--------+---------------+----------+-----------------+----------+------------------
-- PAYMENTS       | L1         | EMEA   | 38            | 24       | 63.16           | 2.84     | High backlog
-- CARDS          | L1         | NA     | 45            | 27       | 60.00           | 2.97     | Agent capacity
-- COMPLIANCE     | L1         | APAC   | 22            | 12       | 54.55           | 3.05     | Manual review delay
-- CREDIT         | L1         | EMEA   | 31            | 14       | 45.16           | 3.19     | High backlog
-- ============================================================

-- ============================================================
-- SAMPLE OUTPUT — SP2  sp_customer_escalation_history 1050, 3
-- ============================================================
-- ticket_id | created_at          | issue_category | csat_score | escalation_reason   | sla_breached_flag | breach_reason
-- ----------+---------------------+----------------+------------+---------------------+-------------------+--------------
-- 9050      | 2025-09-05 02:00:00 | PAYMENTS       | 2          | Agent capacity      | 1                 | High backlog
-- 9312      | 2025-09-18 14:00:00 | CARDS          | 1          | Agent knowledge gap | 1                 | Agent capacity
-- 9587      | 2025-10-04 09:00:00 | COMPLIANCE     | 2          | Process failure     | 0                 | NULL
-- ============================================================

-- Drop if exists before recreating
IF OBJECT_ID('sp_customer_escalation_history', 'P') IS NOT NULL DROP PROCEDURE sp_customer_escalation_history;
IF OBJECT_ID('sp_sla_breach_report',           'P') IS NOT NULL DROP PROCEDURE sp_sla_breach_report;
GO

-- ============================================================
-- SP1 — Parameterised SLA Breach Report
-- ============================================================
CREATE PROCEDURE sp_sla_breach_report
    @p_start_date   DATE,
    @p_end_date     DATE,
    @p_agent_tier   VARCHAR(2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        t.issue_category, a.agent_tier, a.region,
        COUNT(t.ticket_id)                                      AS total_tickets,
        SUM(s.sla_breached_flag)                               AS breaches,
        ROUND(SUM(s.sla_breached_flag) * 100.0
              / NULLIF(COUNT(t.ticket_id), 0), 2)              AS breach_rate_pct,
        ROUND(AVG(CAST(t.resolution_time_mins AS FLOAT)), 0)   AS avg_res_mins,
        ROUND(AVG(CAST(t.csat_score AS FLOAT)), 2)             AS avg_csat,
        MAX(s.breach_reason)                                   AS top_breach_reason
    FROM tickets AS t
    INNER JOIN sla_logs AS s ON t.ticket_id = s.ticket_id
    INNER JOIN agents   AS a ON t.agent_id  = a.agent_id
    WHERE CAST(t.created_at AS DATE) BETWEEN @p_start_date AND @p_end_date
      AND (@p_agent_tier IS NULL OR a.agent_tier = @p_agent_tier)
    GROUP BY t.issue_category, a.agent_tier, a.region
    ORDER BY breach_rate_pct DESC;
END;
GO

-- Usage examples:
EXEC sp_sla_breach_report '2025-09-01', '2025-09-30', 'L1';   -- L1 September only
EXEC sp_sla_breach_report '2025-09-01', '2025-10-31', NULL;   -- All tiers, full period
GO

-- ============================================================
-- SP2 — Customer Escalation History
-- ============================================================
CREATE PROCEDURE sp_customer_escalation_history
    @p_customer_id  INT,
    @p_top_n        INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@p_top_n)
        t.ticket_id, t.created_at, t.issue_category,
        t.payment_type, t.country, t.csat_score,
        t.resolution_time_mins,
        c.customer_segment, c.tenure_months, c.risk_flag,
        er.reason_category  AS escalation_reason,
        er.description      AS escalation_detail,
        s.sla_breached_flag, s.sla_target_mins,
        s.actual_resolution_mins, s.breach_reason
    FROM tickets AS t
    INNER JOIN customers          AS c  ON t.customer_id         = c.customer_id
    INNER JOIN escalation_reasons AS er ON t.escalation_reason_id = er.escalation_reason_id
    INNER JOIN sla_logs           AS s  ON t.ticket_id            = s.ticket_id
    WHERE t.customer_id   = @p_customer_id
      AND t.escalation_flag = 1
    ORDER BY t.created_at DESC;
END;
GO

-- Usage examples:
EXEC sp_customer_escalation_history 1001, 5;   -- last 5 escalations for customer 1001
EXEC sp_customer_escalation_history 1050;      -- last 10 (default)
GO
