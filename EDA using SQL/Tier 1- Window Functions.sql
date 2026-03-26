
-- ============================================================
-- Q1: Agent Ranking by Escalation Rate Within Tier
-- Week-over-Week 
-- "Which agents within each tier consistently escalate the most, and how does their rank change week-over-week?" | 
-- Uses: tickets JOIN agents
-- ============================================================

-- STEP 1: Aggregate weekly ticket & escalation counts per agent
--         JOIN brings in agent_tier from the agents table

WITH weekly_agent_stats AS (
    SELECT
        a.agent_id,
        a.agent_tier,
        a.region,

        -- ISO week label: e.g. "2025-W36"
        CAST(YEAR(t.created_at) AS VARCHAR) + '-W'
        + RIGHT('0' + CAST(DATEPART(ISO_WEEK, t.created_at) AS VARCHAR), 2)
                                                        AS iso_week,

        -- Monday of that ISO week (for clean ordering)
        DATEADD(DAY,
            1 - DATEPART(WEEKDAY, t.created_at
                + @@DATEFIRST - 2),
            CAST(t.created_at AS DATE))                 AS week_start_date,

        COUNT(t.ticket_id)                              AS total_tickets,
        SUM(t.escalation_flag)                          AS total_escalations

    FROM tickets AS t
    INNER JOIN agents AS a
        ON t.agent_id = a.agent_id

    GROUP BY
        a.agent_id,
        a.agent_tier,
        a.region,
        CAST(YEAR(t.created_at) AS VARCHAR) + '-W'
            + RIGHT('0' + CAST(DATEPART(ISO_WEEK, t.created_at) AS VARCHAR), 2),
        DATEADD(DAY,
            1 - DATEPART(WEEKDAY, t.created_at
                + @@DATEFIRST - 2),
            CAST(t.created_at AS DATE))
),


-- STEP 2: Calculate escalation rate and rank each agent
--         within their tier for every week
agent_weekly_ranked AS (
    SELECT
        agent_id,
        agent_tier,
        region,
        iso_week,
        week_start_date,
        total_tickets,
        total_escalations,

        -- Escalation rate (%) for this agent this week
        ROUND(
            total_escalations * 100.0 / NULLIF(total_tickets, 0),
        2)                                              AS esc_rate_pct,

        -- Rank 1 = highest escalator within the tier that week
        RANK() OVER (
            PARTITION BY agent_tier, iso_week
            ORDER BY
                total_escalations * 1.0
                / NULLIF(total_tickets, 0) DESC
        )                                               AS esc_rank_in_tier,

        -- Running cumulative tickets across all weeks for this agent
        SUM(total_tickets) OVER (
            PARTITION BY agent_id
            ORDER BY week_start_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                               AS cumulative_tickets

    FROM weekly_agent_stats
),

-- STEP 3: Compare this week's rank to last week's rank
--         LAG() looks back 1 week for the same agent
agent_rank_movement AS (
    SELECT
        agent_id,
        agent_tier,
        region,
        iso_week,
        week_start_date,
        total_tickets,
        total_escalations,
        esc_rate_pct,
        esc_rank_in_tier,
        cumulative_tickets,

        -- Previous week's rank for this agent (within same tier)
        LAG(esc_rank_in_tier) OVER (
            PARTITION BY agent_id
            ORDER BY week_start_date
        )                                               AS prev_week_rank,

        -- Positive = rank worsened (climbed toward #1 escalator)
        -- Negative = rank improved (dropped away from #1)
        esc_rank_in_tier -
        LAG(esc_rank_in_tier) OVER (
            PARTITION BY agent_id
            ORDER BY week_start_date
        )                                               AS rank_change_wow,

        -- Human-readable direction label
        CASE
            WHEN esc_rank_in_tier <
                 LAG(esc_rank_in_tier) OVER (
                     PARTITION BY agent_id ORDER BY week_start_date)
                 THEN '↑ Worse (more escalations)'
            WHEN esc_rank_in_tier >
                 LAG(esc_rank_in_tier) OVER (
                     PARTITION BY agent_id ORDER BY week_start_date)
                 THEN '↓ Better (fewer escalations)'
            WHEN LAG(esc_rank_in_tier) OVER (
                     PARTITION BY agent_id ORDER BY week_start_date)
                 IS NULL
                 THEN '— First week'
            ELSE                                          '→ No change'
        END                                             AS rank_trend

    FROM agent_weekly_ranked
)

-- ============================================================
-- FINAL OUTPUT: All agents, all weeks, ranked within tier
-- ============================================================
SELECT
    agent_tier,
    iso_week,
    week_start_date,
    agent_id,
    region,
    total_tickets,
    total_escalations,
    esc_rate_pct,
    esc_rank_in_tier,
    prev_week_rank,
    rank_change_wow,
    rank_trend,
    cumulative_tickets
FROM agent_rank_movement
ORDER BY
    agent_tier,
    week_start_date,
    esc_rank_in_tier;
