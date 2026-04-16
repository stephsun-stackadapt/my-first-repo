create or replace view ACCOUNT_CAS_V_NEW(
	SF_ACCOUNT_ID,
	ACCOUNT_ID,
	USER_ID,
	CHILD_ID,
	CAS_CG,
	CAS_CAMPAIGN,
	TOTAL_COMMITTED_SPEND,
    CAS_CG_THRU_NEXT_QTR,
    CAS_CAMPAIGN_THRU_NEXT_QTR,
    TOTAL_COMMITTED_SPEND_THRU_NEXT_QTR,
    NEXT_QTR_CAS_CG,
    NEXT_QTR_CAS_CAMPAIGN,
    NEXT_QTR_TOTAL_COMMITTED_SPEND,
	ACCOUNT_NAME,
	CSM_SUPPORT_TYPE,
	VP_NAME,
	AE_NAME,
	AE_ID
) as

--BASE QUERY, CAS AT CHILD_ID  LEVEL
WITH CAS_END_DATE AS (
    SELECT 
    LAST_DAY(DATEADD(QUARTER, 0, CURRENT_DATE), 'QUARTER') AS CAS_END_DATE_CURRENT,
    LAST_DAY(DATEADD(QUARTER, 1, CURRENT_DATE), 'QUARTER') AS CAS_END_DATE_NEXT
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
                     OR CG.CG_START_DATE > CE.CAS_END_DATE_CURRENT
                     OR CG.CG_END_DATE <= CURRENT_DATE
                THEN 0
                ELSE
                    CASE
                        WHEN CG.CG_END_DATE <= CE.CAS_END_DATE_CURRENT THEN
                            GREATEST(0, CG.CG_FLIGHT_BUDGET_USD - COALESCE(CG.CG_COST_USD, 0))
                        ELSE
                            GREATEST(
                                0,
                                (CG.CG_FLIGHT_BUDGET_USD - COALESCE(CG.CG_COST_USD, 0))
                                * LEAST(
                                    DATEDIFF('DAY', CURRENT_DATE, CG.CG_END_DATE),
                                    DATEDIFF('DAY', CURRENT_DATE, CE.CAS_END_DATE_CURRENT)
                                )
                                / NULLIF(DATEDIFF('DAY', CG.CG_START_DATE, CG.CG_END_DATE), 0)
                            )
                    END
            END
        ) AS CAS_CG,

        SUM(
            CASE
                WHEN CG.CG_FLIGHT_NO_OF_DAYS = 0
                     OR CG.CG_FLIGHT_NO_OF_DAYS IS NULL
                     OR CG.CG_START_DATE > CE.CAS_END_DATE_NEXT
                     OR CG.CG_END_DATE <= CURRENT_DATE
                THEN 0
                ELSE
                    CASE
                        WHEN CG.CG_END_DATE <= CE.CAS_END_DATE_NEXT THEN
                            GREATEST(0, CG.CG_FLIGHT_BUDGET_USD - COALESCE(CG.CG_COST_USD, 0))
                        ELSE
                            GREATEST(
                                0,
                                (CG.CG_FLIGHT_BUDGET_USD - COALESCE(CG.CG_COST_USD, 0))
                                * LEAST(
                                    DATEDIFF('DAY', CURRENT_DATE, CG.CG_END_DATE),
                                    DATEDIFF('DAY', CURRENT_DATE, CE.CAS_END_DATE_NEXT)
                                )
                                / NULLIF(DATEDIFF('DAY', CG.CG_START_DATE, CG.CG_END_DATE), 0)
                            )
                    END
            END
        ) AS CAS_CG_THRU_NEXT_QTR

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
                     OR CAMP.START_DATE > CE.CAS_END_DATE_CURRENT
                     OR CAMP.END_DATE <= CURRENT_DATE
                THEN 0
                ELSE
                    CASE
                        WHEN CAMP.END_DATE <= CE.CAS_END_DATE_CURRENT THEN
                            GREATEST(0, CAMP.CAMPAIGN_FLIGHT_BUDGET_USD - COALESCE(CAMP.CURRENT_FLIGHT_CAMPAIGN_COST_USD, 0))
                        ELSE
                            GREATEST(
                                0,
                                (CAMP.CAMPAIGN_FLIGHT_BUDGET_USD - COALESCE(CAMP.CURRENT_FLIGHT_CAMPAIGN_COST_USD, 0))
                                * LEAST(
                                    DATEDIFF('DAY', CURRENT_DATE, CAMP.END_DATE),
                                    DATEDIFF('DAY', CURRENT_DATE, CE.CAS_END_DATE_CURRENT)
                                )
                                / NULLIF(DATEDIFF('DAY', CAMP.START_DATE, CAMP.END_DATE), 0)
                            )
                    END
            END
        ) AS CAS_CAMPAIGN,

        SUM(
            CASE
                WHEN CAMP.CAMPAIGN_FLIGHT_NO_OF_DAYS = 0
                     OR CAMP.CAMPAIGN_FLIGHT_NO_OF_DAYS IS NULL
                     OR CAMP.START_DATE > CE.CAS_END_DATE_NEXT
                     OR CAMP.END_DATE <= CURRENT_DATE
                THEN 0
                ELSE
                    CASE
                        WHEN CAMP.END_DATE <= CE.CAS_END_DATE_NEXT THEN
                            GREATEST(0, CAMP.CAMPAIGN_FLIGHT_BUDGET_USD - COALESCE(CAMP.CURRENT_FLIGHT_CAMPAIGN_COST_USD, 0))
                        ELSE
                            GREATEST(
                                0,
                                (CAMP.CAMPAIGN_FLIGHT_BUDGET_USD - COALESCE(CAMP.CURRENT_FLIGHT_CAMPAIGN_COST_USD, 0))
                                * LEAST(
                                    DATEDIFF('DAY', CURRENT_DATE, CAMP.END_DATE),
                                    DATEDIFF('DAY', CURRENT_DATE, CE.CAS_END_DATE_NEXT)
                                )
                                / NULLIF(DATEDIFF('DAY', CAMP.START_DATE, CAMP.END_DATE), 0)
                            )
                    END
            END
        ) AS CAS_CAMPAIGN_THRU_NEXT_QTR

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
        COALESCE(CG.CAS_CG, 0) + COALESCE(CAMP.CAS_CAMPAIGN, 0) AS TOTAL_COMMITTED_SPEND,

        COALESCE(CG.CAS_CG_THRU_NEXT_QTR, 0) AS CAS_CG_THRU_NEXT_QTR,
        COALESCE(CAMP.CAS_CAMPAIGN_THRU_NEXT_QTR, 0) AS CAS_CAMPAIGN_THRU_NEXT_QTR,
        COALESCE(CG.CAS_CG_THRU_NEXT_QTR, 0) + COALESCE(CAMP.CAS_CAMPAIGN_THRU_NEXT_QTR, 0) AS TOTAL_COMMITTED_SPEND_THRU_NEXT_QTR

    FROM CAS_CG CG
    FULL OUTER JOIN CAS_CAMPAIGN CAMP
        ON CG.SF_ACCOUNT_ID = CAMP.SF_ACCOUNT_ID
       AND COALESCE(CG.ACCOUNT_ID, -1) = COALESCE(CAMP.ACCOUNT_ID, -1)

)

SELECT
    CAS.SF_ACCOUNT_ID,
    CAS.ACCOUNT_ID,
    CAS.USER_ID,
    CAS.CHILD_ID,

    CAS.CAS_CG,
    CAS.CAS_CAMPAIGN,
    CAS.TOTAL_COMMITTED_SPEND,

    CAS.CAS_CG_THRU_NEXT_QTR,
    CAS.CAS_CAMPAIGN_THRU_NEXT_QTR,
    CAS.TOTAL_COMMITTED_SPEND_THRU_NEXT_QTR,

    CAS.CAS_CG_THRU_NEXT_QTR - CAS.CAS_CG AS NEXT_QTR_CAS_CG,
    CAS.CAS_CAMPAIGN_THRU_NEXT_QTR - CAS.CAS_CAMPAIGN AS NEXT_QTR_CAS_CAMPAIGN,
    CAS.TOTAL_COMMITTED_SPEND_THRU_NEXT_QTR - CAS.TOTAL_COMMITTED_SPEND AS NEXT_QTR_TOTAL_COMMITTED_SPEND,

    A.NAME AS ACCOUNT_NAME,
    A.CSM_SUPPORT_TYPE__C AS CSM_SUPPORT_TYPE,
    H.VP_NAME,
    H.AE_NAME,
    H.AE_ID
FROM CAS
LEFT JOIN DM.BI.SECURE_SF_REVOPS_ACCOUNTS A
    ON CAS.SF_ACCOUNT_ID = A.ID
LEFT JOIN sales_team H
    ON A.OWNERID = H.AE_ID
ORDER BY
    CAS.SF_ACCOUNT_ID,
    CAS.ACCOUNT_ID;