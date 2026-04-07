//avg monthly per quarter
WITH filtered_accounts AS (
    SELECT
        u.user_account_pk,
        u.intacct_id,
        p.parent_erp_id,
        m.companyname
    FROM DM.BI.D_USER_ACCOUNT_V u
    JOIN DM.BI.PARENT_CHILD_ERP_ID_MAPPING_V m
        ON m.erp_id = u.intacct_id
    JOIN DM.BI.CHILD_TO_PARENT_ERP_ID p
        ON p.child_erp_id = u.intacct_id
    WHERE p.parent_erp_id = 'C-00800P'
),
sales_quarterly AS (
    SELECT
        s.user_account_pk,
        d.year,
        d.quarter,
        SUM(s.gas_usd)/3 AS gas_usd_sum
    FROM DM.BI.F_DAILY_SALES_V_NEW s
    JOIN DM.BI.D_DATE_V d
        ON s.date_pk = d.date_pk
    WHERE d.calendar_date >= DATE '2025-05-01'
      AND d.calendar_date <  DATE '2026-05-01'
    GROUP BY
        s.user_account_pk,
        d.year,
        d.quarter
)
SELECT
    fa.parent_erp_id,
    fa.intacct_id,
    fa.companyname,
    sq.year,
    sq.quarter,
    sq.gas_usd_sum
FROM sales_quarterly sq
JOIN filtered_accounts fa
    ON sq.user_account_pk = fa.user_account_pk
ORDER BY
    fa.parent_erp_id,
    fa.intacct_id,
    fa.companyname,
    sq.year,
    sq.quarter;



//monthly gas
WITH filtered_accounts AS (
    SELECT
        u.user_account_pk,
        u.intacct_id,
        p.parent_erp_id,
        m.companyname
    FROM DM.BI.D_USER_ACCOUNT_V u
    JOIN DM.BI.PARENT_CHILD_ERP_ID_MAPPING_V m
        ON m.erp_id = u.intacct_id
    JOIN DM.BI.CHILD_TO_PARENT_ERP_ID p
        ON p.child_erp_id = u.intacct_id
    WHERE p.parent_erp_id = 'C-00800P'
),
sales_monthly AS (
    SELECT
        s.user_account_pk,
        d.year,
        d.month_of_year,
        SUM(s.gas_usd) AS gas_usd_sum
    FROM DM.BI.F_DAILY_SALES_V_NEW s
    JOIN DM.BI.D_DATE_V d
        ON s.date_pk = d.date_pk
    WHERE d.calendar_date >= DATE '2025-05-01'
      AND d.calendar_date <  DATE '2026-05-01'
    GROUP BY
        s.user_account_pk,
        d.year,
        d.month_of_year
)
SELECT
    fa.parent_erp_id,
    fa.intacct_id,
    fa.companyname,
    sm.year,
    sm.month_of_year,
    sm.gas_usd_sum
FROM sales_monthly sm
JOIN filtered_accounts fa
    ON sm.user_account_pk = fa.user_account_pk
ORDER BY
    fa.parent_erp_id,
    fa.intacct_id,
    fa.companyname,
    sm.year,
    sm.month_of_year;