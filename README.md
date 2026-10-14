# **Insurance Claims & Risk Segmentation Pipeline**

**An end-to-end data pipeline that ingests claims, detects financial leakage, and automates risk triage.**

---

## Data Source
* **[Insurance Claims Dataset 2026](https://www.kaggle.com/datasets/mmumairkhattak/insurance-claims-dataset-2026-fd-and-ra)**: Ingested and structured 50,000 historical insurance claims records containing policy rules and payout history.


## Technologies Used
* **SQL (PostgreSQL)**
* **Power BI**


## Key Features
* **Three-Tier Risk Segmentation**: Programmed a triage system utilizing SQL CTEs and Window Functions to categorize claims into Low, Medium, and High risk.


## Results
* Isolated critical policy violations showing that **9.2% of settled payouts exceeded their policy coverage limits**.
* Safely **auto-approved 59% of all incoming claims** by verifying them as low-risk, significantly reducing manual overhead.
* Enabled operational teams to effectively prioritize a heavy backlog of **20,000+ claims** awaiting investigation.

