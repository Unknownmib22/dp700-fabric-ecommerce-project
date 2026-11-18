# ms-fabric-ecommerce-project
# End-to-End E-Commerce Data Engineering Pipeline in Microsoft Fabric

## 📋 Project Overview
This project implements an automated, end-to-end data engineering solution in **Microsoft Fabric** using the **Medallion Architecture** (Bronze, Silver, Gold). It ingests raw customer and e-commerce data, performs Spark-based data cleansing and standardization, and builds a dimensional Star Schema in a Fabric Warehouse ready for Power BI analytics.

---

## 🏗️ Architecture & Data Flow

```text
[Raw Data Sources]
        │
        ▼ (Dataflow Gen2 / Copy Job)
┌───────────────────────────┐
│      BRONZE LAYER         │  Raw ingestion into Lakehouse
│   (df_ingest_customers,   │
│        CopyJob_1)         │
└─────────────┬─────────────┘
              │
              ▼ (PySpark Notebook: nb_transform_silver)
┌───────────────────────────┐
│      SILVER LAYER         │  Data cleaning, deduplication & schema enforcement
│     (Curated Tables)      │
└─────────────┬─────────────┘
              │
              ▼ (T-SQL Stored Procedure)
┌───────────────────────────┐
│       GOLD LAYER          │  Star Schema (Fact & Dimension tables)
│    (wh_ecommerce_gold)    │
└─────────────┬─────────────┘
              │
              ▼
┌───────────────────────────┐
│     BI & REPORTING        │  DirectLake / Power BI Semantic Model
└───────────────────────────┘
```

---

## 🛠️ Tech Stack & Fabric Artifacts

| Layer / Component | Artifact Name | Fabric Item Type | Purpose |
| :--- | :--- | :--- | :--- |
| **Orchestration** | `pl_master_orchestrator` | Data Pipeline | Coordinates sequential execution across Bronze, Silver, and Gold layers. |
| **Bronze (Ingestion)** | `df_ingest_customers` | Dataflow Gen2 | Extracts and loads raw customer data into the Bronze layer. |
| **Bronze (Ingestion)** | `CopyJob_1` | Copy Job | High-throughput ingestion of raw transactional/e-commerce files. |
| **Silver (Transform)** | `nb_transform_silver` | Spark Notebook | Cleans null values, standardizes formats, deduplicates records, and writes Delta tables. |
| **Gold (Serving)** | `wh_ecommerce_gold` | Data Warehouse | Stores business-ready Fact and Dimension tables modeled as a Star Schema. |

---

## 🔄 Orchestration Workflow (`pl_master_orchestrator`)

The master pipeline enforces strict sequential dependencies (`On Success`) to guarantee data integrity across stages:

1. **`Run_Bronze_Ingestion` (Invoke Pipeline)**
   * Triggers child ingestion workflows (`df_ingest_customers` and `CopyJob_1`) to land raw data into OneLake.
2. **`Run_Silver_Transform` (Notebook)**
   * Executes `nb_transform_silver` once raw ingestion succeeds, transforming raw data into validated Silver Delta tables.
3. **`Run_Gold_Star_Schema` (Stored Procedure)**
   * Runs a T-SQL stored procedure inside `wh_ecommerce_gold` to load and update Dimension and Fact tables.

---

## 🚀 Setup & Deployment Guide

### Prerequisites
* An active **Microsoft Fabric** capacity (Trial or F-SKU).
* A dedicated Fabric Workspace with Lakehouse, Warehouse, Data Pipeline, and Notebook permissions enabled.

### Steps to Reproduce
1. **Clone/Import Artifacts:** Import the pipeline (`pl_master_orchestrator`), notebook (`nb_transform_silver`), and warehouse DDL/stored procedures into your Fabric workspace.
2. **Configure Connections:** Update source credentials in `df_ingest_customers` and `CopyJob_1` to point to your raw data source.
3. **Verify Lakehouse & Warehouse Bindings:**
   * Attach your default Lakehouse to `nb_transform_silver`.
   * Confirm the Warehouse connection inside the `Run_Gold_Star_Schema` activity in `pl_master_orchestrator`.
4. **Validate & Run:**
   * Open `pl_master_orchestrator` and click **Validate** to verify zero configuration errors.
   * Click **Run** (or configure **Schedule**) to execute the end-to-end pipeline.

---

## ✅ Validation & Execution Results
* **Pipeline Validation:** Passed with 0 errors.
* **End-to-End Execution:** Verified successful sequential completion across all three stages (~6 minutes total runtime).

---

## 🔮 Future Enhancements
* [ ] Add automated failure alerting via Office 365 Outlook or Microsoft Teams on `On Fail` paths.
* [ ] Implement incremental watermarking for large fact tables in the Bronze and Silver layers.
* [ ] Build a Power BI report connected to `wh_ecommerce_gold` via DirectLake mode.
