--understanding users vs native ads

select * from ASBWZPT_STACKADAPT_REPORTING_STATS_REPORTING_SNOWFLAKE_SECURE_SHARE_1690485758008.REPORTS.USERS 
where "sf_account_id" = '0011Q00002EmRV2';

select * from ASBWZPT_STACKADAPT_REPORTING_STATS_REPORTING_SNOWFLAKE_SECURE_SHARE_1690485758008.REPORTS.NATIVE_ADS
where "user_id" in (
    14505,
14506,
14507,
14508,
14504
);


select * from INB.SFSC_NEW
limit 100;


select * from DATA_LAB.REVOPS.CAMPAIGN_PACING
limit 100;

select * from DATA_LAB.REVOPS.CAS_VIEW_CAMPAIGN
limit 100;


select * from DM.BI.ACCOUNT_CAS_V limit 100;


SELECT 
    USER_ACCOUNT_PK,
    CONCAT(YEAR(DATE), '-Q', QUARTER(DATE)) AS QUARTER,
    SUM(GAS_USD) / 3 AS AVG_GAS_USD
FROM DM.BI.F_DAILY_SALES_V
WHERE USER_ACCOUNT_PK = 1690806
    AND DATE BETWEEN '2025-07-01' AND '2026-03-24'
GROUP BY 
    USER_ACCOUNT_PK,
    YEAR(DATE),
    QUARTER(DATE)
ORDER BY QUARTER DESC;



SELECT 
    USER_ACCOUNT_PK,
    SUM(GAS_USD)/12 AS Last12MonthGAS
FROM DM.BI.F_DAILY_SALES_V 
WHERE USER_ACCOUNT_PK = 1690806
    AND DATE BETWEEN '2025-02-01' AND '2026-03-24'
GROUP BY 
    USER_ACCOUNT_PK;

SELECT 
    USER_ACCOUNT_PK,
     CONCAT(YEAR(DATE), '-', MONTH(DATE)) AS MONTH,
    SUM(GAS_USD)
FROM DM.BI.F_DAILY_SALES_V 
WHERE USER_ACCOUNT_PK = 1690806
    AND DATE BETWEEN '2025-02-01' AND '2026-03-24'
GROUP BY 
    USER_ACCOUNT_PK,
    YEAR(DATE),
    MONTH
ORDER BY YEAR(DATE), MONTH ASC;




SELECT * FROM DM.BI.PARENT_CHILD_ERP_ID_MAPPING_V LIMIT 25;

SELECT 
PARENT_ERP_ID,
COUNT(CHILD_ERP_ID) AS NumberOfChildID
FROM DM.BI.CHILD_TO_PARENT_ERP_ID
GROUP BY PARENT_ERP_ID;

SELECT DISTINCT * FROM DM.BI.D_USER_ACCOUNT_V LIMIT 100;


SELECT DISTINCT CREDIT_ANALYST FROM DM.BI.D_USER_ACCOUNT_V ORDER BY CREDIT_ANALYST ASC;

select c.id, c.externalid, c.entityid, c.custentity_cg_approved_payment_terms, t.name from inb.netsuite.customer c
join inb.netsuite.term t on c.custentity_cg_approved_payment_terms = t.id;

SELECT
    c.CHILD_COMPANYNAME,
    c.CHILD_ERP_ID,
    b."approved_payment_terms"
FROM ASBWZPT_STACKADAPT_REPORTING_STATS_REPORTING_SNOWFLAKE_SECURE_SHARE_1690485758008.REPORTS.BILLING_DATA b
JOIN DM.BI.CHILD_TO_PARENT_ERP_ID c
    ON b."netsuite_display_id" = c.CHILD_ERP_ID
WHERE "approved_payment_terms" ILIKE '%net%';


select "id", "requested_payment_terms", "approved_payment_terms" 
from asbwzpt_stackadapt_reporting_stats_reporting_snowflake_secure_share_1690485758008.reports.billing_data limit 100;


select metric_date,sf_account_id,account_id,sum(metric_value)from DATA_LAB.REVOPS.CAS_DAILY_OBT where

metric_name='cas_margin_usd'--sf_account_id='0011Q00002IEVtWQAX'  and  metric_name='cas_margin_usd'

group by 1,2,3;

SELECT * FROM DATA_LAB.REVOPS.CAS_DAILY_OBT WHERE METRIC_DATE >= CURRENT_DATE
ORDER BY METRIC_DATE ASC LIMIT 100;

SELECT DISTINCT METRIC_NAME FROM DATA_LAB.REVOPS.CAS_DAILY_OBT;

select * from account_cas_v_new limit 100;


select 
    DATE_TRUNC('QUARTER', METRIC_DATE)::DATE AS QUARTER,
    sf_account_id,
    account_id,
    sum(metric_value)
from DATA_LAB.REVOPS.CAS_DAILY_OBT 
where metric_name='cas_margin_usd' and METRIC_DATE >= CURRENT_DATE
group by 1,2,3;