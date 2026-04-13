create or replace view ACCOUNT_CAS_V_NEW(
	SF_ACCOUNT_ID,
	ACCOUNT_ID,
	USER_ID,
	CHILD_ID,
	CAS_CG,
	CAS_CAMPAIGN,
	TOTAL_COMMITTED_SPEND,
	ACCOUNT_NAME,
	CSM_SUPPORT_TYPE,
	VP_NAME,
	AE_NAME,
	AE_ID
) as

WITH CAS_END_DATE AS (
    SELECT LAST_DAY(DATEADD(QUARTER, 0, CURRENT_DATE), 'QUARTER') AS CAS_END_DATE
),

sales_team AS (
    SELECT DISTINCT
        ACCOUNT_OWNER_ID__C AS AE_ID,
        AE_NAME,
        VP_SALES_NAME AS VP_NAME
    FROM DM.BI.SECURE_SF_REVOPS_ACCOUNTS
),

CAS_CG AS (
    SELECT
        CG.SF_ACCOUNT_ID,
        UA.USER_ACCOUNT_PK AS ACCOUNT_ID,
        UA.USER_ID,
        UA.INTACCT_ID AS CHILD_ID,
        SUM(
            CASE
                WHEN CG.CG_FLIGHT_NO_OF_DAYS = 0
                     OR CG.CG_FLIGHT_NO_OF_DAYS IS NULL
                     OR CG.CG_START_DATE > CE.CAS_END_DATE
                     OR CG.CG_END_DATE <= CURRENT_DATE
                THEN 0
                ELSE
                    CASE
                        WHEN CG.CG_END_DATE <= CE.CAS_END_DATE THEN
                            GREATEST(0, CG.CG_FLIGHT_BUDGET_USD - COALESCE(CG.CG_COST_USD, 0))
                        ELSE
                            GREATEST(
                                0,
                                (CG.CG_FLIGHT_BUDGET_USD - COALESCE(CG.CG_COST_USD, 0))
                                * LEAST(
                                    DATEDIFF('DAY', CURRENT_DATE, CG.CG_END_DATE),
                                    DATEDIFF('DAY', CURRENT_DATE, CE.CAS_END_DATE)
                                )
                                / DATEDIFF('DAY', CG.CG_START_DATE, CG.CG_END_DATE)
                            )
                    END
            END
        ) AS CAS_CG
    FROM DATA_LAB.REVOPS.CAS_VIEW_CG CG
    CROSS JOIN CAS_END_DATE CE
    LEFT JOIN DM.BI.D_USER_ACCOUNT_V UA
        ON CG.ACCOUNT_ID = UA.USER_ACCOUNT_PK
    GROUP BY
        CG.SF_ACCOUNT_ID,
        UA.USER_ACCOUNT_PK,
        UA.USER_ID,
        UA.INTACCT_ID
),

CAS_CAMPAIGN AS (
    SELECT
        CAMP.SF_ACCOUNT_ID,
        UA.USER_ACCOUNT_PK AS ACCOUNT_ID,
        UA.USER_ID,
        UA.INTACCT_ID AS CHILD_ID,
        SUM(
            CASE
                WHEN CAMP.CAMPAIGN_FLIGHT_NO_OF_DAYS = 0
                     OR CAMP.CAMPAIGN_FLIGHT_NO_OF_DAYS IS NULL
                     OR CAMP.START_DATE > CE.CAS_END_DATE
                     OR CAMP.END_DATE <= CURRENT_DATE
                THEN 0
                ELSE
                    CASE
                        WHEN CAMP.END_DATE <= CE.CAS_END_DATE THEN
                            GREATEST(0, CAMP.CAMPAIGN_FLIGHT_BUDGET_USD - COALESCE(CAMP.CURRENT_FLIGHT_CAMPAIGN_COST_USD, 0))
                        ELSE
                            GREATEST(
                                0,
                                (CAMP.CAMPAIGN_FLIGHT_BUDGET_USD - COALESCE(CAMP.CURRENT_FLIGHT_CAMPAIGN_COST_USD, 0))
                                * LEAST(
                                    DATEDIFF('DAY', CURRENT_DATE, CAMP.END_DATE),
                                    DATEDIFF('DAY', CURRENT_DATE, CE.CAS_END_DATE)
                                )
                                / DATEDIFF('DAY', CAMP.START_DATE, CAMP.END_DATE)
                            )
                    END
            END
        ) AS CAS_CAMPAIGN
    FROM DATA_LAB.REVOPS.CAS_VIEW_CAMPAIGN CAMP
    CROSS JOIN CAS_END_DATE CE
    LEFT JOIN DM.BI.D_USER_ACCOUNT_V UA
        ON CAMP.ACCOUNT_ID = UA.USER_ACCOUNT_PK
    GROUP BY
        CAMP.SF_ACCOUNT_ID,
        UA.USER_ACCOUNT_PK,
        UA.USER_ID,
        UA.INTACCT_ID
),

CAS AS (
    SELECT
        COALESCE(CG.SF_ACCOUNT_ID, CAMP.SF_ACCOUNT_ID) AS SF_ACCOUNT_ID,
        COALESCE(CG.ACCOUNT_ID, CAMP.ACCOUNT_ID) AS ACCOUNT_ID,
        COALESCE(CG.USER_ID, CAMP.USER_ID) AS USER_ID,
        COALESCE(CG.CHILD_ID, CAMP.CHILD_ID) AS CHILD_ID,
        COALESCE(CG.CAS_CG, 0) AS CAS_CG,
        COALESCE(CAMP.CAS_CAMPAIGN, 0) AS CAS_CAMPAIGN,
        COALESCE(CG.CAS_CG, 0) + COALESCE(CAMP.CAS_CAMPAIGN, 0) AS TOTAL_COMMITTED_SPEND
    FROM CAS_CG CG
    FULL OUTER JOIN CAS_CAMPAIGN CAMP
        ON CG.SF_ACCOUNT_ID = CAMP.SF_ACCOUNT_ID
       AND COALESCE(CG.ACCOUNT_ID, -1) = COALESCE(CAMP.ACCOUNT_ID, -1)
)

SELECT
    C.SF_ACCOUNT_ID,
    C.ACCOUNT_ID,
    C.USER_ID,
    C.CHILD_ID,
    C.CAS_CG,
    C.CAS_CAMPAIGN,
    C.TOTAL_COMMITTED_SPEND,
    A.NAME AS ACCOUNT_NAME,
    A.CSM_SUPPORT_TYPE__C AS CSM_SUPPORT_TYPE,
    H.VP_NAME,
    H.AE_NAME,
    H.AE_ID
FROM CAS C
LEFT JOIN DM.BI.SECURE_SF_REVOPS_ACCOUNTS A
    ON C.SF_ACCOUNT_ID = A.ID
LEFT JOIN sales_team H
    ON A.OWNERID = H.AE_ID
ORDER BY
    C.SF_ACCOUNT_ID,
    C.ACCOUNT_ID;