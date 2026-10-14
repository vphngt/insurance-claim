-- -----------------------------------------------------
-- data quality checks
-- -----------------------------------------------------
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT claim_id) AS unique_claims,
    SUM((claim_amount > coverage_amount)::int) AS claims_over_coverage,
    SUM((claim_amount IS NULL OR premium_amount IS NULL
		OR settlement_amount IS NULL)::int) AS rows_with_nulls
FROM insurance_claims;

-- -----------------------------------------------------
-- payout-to-premium by policy type
-- money coming in vs money going out
-- checking which policy line is losing the most
-- -----------------------------------------------------
SELECT
	policy_type,
    COUNT(*) AS claims,
    SUM(premium_amount) AS total_premiums,
    SUM(settlement_amount) AS total_settled,
    ROUND((SUM(settlement_amount) / SUM(premium_amount))::numeric, 2) AS payout_to_premium
FROM insurance_claims
GROUP BY policy_type
ORDER BY payout_to_premium DESC;

-- -----------------------------------------------------
-- settlements paid above the policy coverage limit
-- how many time did we overpay a customer's contract?
-- -----------------------------------------------------
SELECT
    COUNT(*) FILTER (WHERE settlement_amount > coverage_amount) AS settled_over_coverage,
    ROUND(SUM(GREATEST(settlement_amount - coverage_amount, 0))::numeric, 0) AS excess_paid
FROM insurance_claims;

-- -----------------------------------------------------
-- check if fraud_flag is just fraud_risk_score > 75
-- -----------------------------------------------------
SELECT
    fraud_flag,
    MIN(fraud_risk_score),
    MAX(fraud_risk_score),
    ROUND(AVG(fraud_risk_score)::numeric, 1) AS avg_score
FROM insurance_claims
GROUP BY fraud_flag;

-- -----------------------------------------------------
-- triage view
-- core logic: 
-- 1. check if they are asking more than their contract allowed
-- 2. compare to their (same region + same claim type) group
-- 3. check if the person has low credit score
-- we dont use settlement to avoid data leakage
-- because it happens after a claim has already been process
-- -----------------------------------------------------
DROP VIEW IF EXISTS claims_triage_view;
CREATE VIEW claims_triage_view AS
WITH scored AS (
    SELECT
        *,
        AVG(claim_amount) OVER peer AS peer_avg_amount,
        COALESCE(
            (claim_amount - AVG(claim_amount) OVER peer) 
			/ NULLIF(STDDEV(claim_amount) OVER peer, 0), 0) AS claim_z_score
    FROM insurance_claims
    WINDOW peer AS (PARTITION BY region, claim_type)
)
SELECT
    *,
    ROUND(peer_avg_amount::numeric, 2) AS peer_group_average,
    ROUND(claim_z_score::numeric, 2) AS claim_deviation,
    (claim_amount > coverage_amount) AS over_coverage,
    GREATEST(settlement_amount - coverage_amount, 0) AS excess_paid,
    CASE
        WHEN (fraud_risk_score > 75)
             AND (claim_amount > coverage_amount OR claim_z_score >= 1.75) THEN 'HIGH RISK: HARD FRAUD'
        WHEN (fraud_risk_score > 75)
             OR (claim_amount > coverage_amount)
             OR (claim_z_score >= 1.75) THEN 'MEDIUM RISK: SOFT FRAUD'
        ELSE 'APPROVED'
    END AS triage_decision
FROM scored;

-- -----------------------------------------------------
-- triage tier
-- how many claims are fast-tracked? 
-- how much suspicious money got caught?
-- -----------------------------------------------------
SELECT
    triage_decision,
    COUNT(*) AS total_claims,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_claims,
    ROUND(AVG(fraud_risk_score)::numeric, 1) AS avg_risk_score,
    SUM((settlement_amount > coverage_amount)::int) AS settled_over_coverage,
    ROUND(SUM(excess_paid)::numeric, 0) AS excess_paid,
    ROUND(SUM(settlement_amount)::numeric, 0) AS total_settled
FROM claims_triage_view
GROUP BY triage_decision
ORDER BY total_claims DESC;

-- -----------------------------------------------------
-- analyzing fraud risk 
-- finding out which has the highest fraud rates
-- across multiple segments
-- -----------------------------------------------------

-- 5a. Claim type
SELECT
    claim_type,
    COUNT(*) AS claims,
    SUM((LOWER(fraud_flag) = 'yes')::int) AS fraud_cases,
    ROUND(100.0 * AVG((LOWER(fraud_flag) = 'yes')::int), 2) AS fraud_rate_pct
FROM insurance_claims
GROUP BY claim_type
ORDER BY fraud_rate_pct DESC;

-- 5b. Region
SELECT
    region,
    COUNT(*) AS claims,
    ROUND(AVG(claim_amount)::numeric, 2) AS avg_claim,
    ROUND(AVG(credit_score)::numeric, 0) AS avg_credit_score,
    SUM((LOWER(fraud_flag) = 'yes')::int) AS fraud_cases,
    ROUND(100.0 * AVG((LOWER(fraud_flag) = 'yes')::int), 2) AS fraud_rate_pct
FROM insurance_claims
GROUP BY region
ORDER BY claims DESC;

-- 5c. Gender and age group
SELECT
    gender,
    CASE WHEN age < 30 THEN 'Under 30'
         WHEN age < 50 THEN '30-49'
         ELSE '50+' END AS age_group,
    COUNT(*) AS claims,
    ROUND(AVG(claim_amount)::numeric, 2) AS avg_claim,
    ROUND(100.0 * AVG((LOWER(fraud_flag) = 'yes')::int), 2) AS fraud_rate_pct
FROM insurance_claims
GROUP BY gender, age_group
ORDER BY fraud_rate_pct DESC;

-- 5d. Credit tier
SELECT
    CASE WHEN credit_score < 500 THEN '1. <500'
         WHEN credit_score < 650 THEN '2. 500-649'
         ELSE '3. 650+' END AS credit_tier,
    COUNT(*) AS claims,
    ROUND(AVG(claim_amount)::numeric, 2) AS avg_claim,
    ROUND(100.0 * AVG((LOWER(fraud_flag) = 'yes')::int), 2) AS fraud_rate_pct
FROM insurance_claims
GROUP BY 1
ORDER BY 1;

-- -----------------------------------------------------
-- full view
-- -----------------------------------------------------
SELECT * FROM claims_triage_view;
