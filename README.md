# **Insurance Claims ELT & Risk Segmentation Pipeline**

**An end-to-end data pipeline that ingests claims, detects financial leakage, and automates risk triaging.**

---

## Data Source
* **Insurance Claims Dataset**: Ingested and structured 50,000 historical insurance claims records containing policy rules and payout history.


## Technologies Used
* **SQL (PostgreSQL)**
* **Power BI**


## Key Features
* **ELT Pipeline & Data Validation**: Built a pipeline to ingest raw data into PostgreSQL and enforced rigid data validation rules.
* **Financial Leakage Quantification**: Designed automated checks to flag over-payments, identifying claims where payouts breached historical limits.
* **Three-Tier Risk Segmentation**: Programmed a triage system utilizing SQL Common Table Expressions (CTEs) and Window Functions to categorize claims into Low, Medium, and High risk.
* **Operational Dashboarding**: Developed a dashboard to track fraud patterns and monitor claims currently bottlenecked in the operational queue.


## Results
* **Plat-Form Leakage Detected**: Isolated critical policy violations showing that **9.2% of settled payouts exceeded their policy coverage limits**.
* **59% Automation Rate**: Safely **auto-approved 59% of all incoming claims** by verifying them as low-risk, significantly reducing manual overhead.
* **Triage Optimization**: Enabled operational teams to effectively prioritize a heavy backlog of **20,000+ claims** awaiting investigation.

