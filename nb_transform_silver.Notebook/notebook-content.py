# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "6300c3ba-9ddb-419b-99ab-955af99a4870",
# META       "default_lakehouse_name": "lh_ecommerce_bronze",
# META       "default_lakehouse_workspace_id": "b6487e18-3230-4128-ada0-d8bdb0c39a44",
# META       "known_lakehouses": [
# META         {
# META           "id": "6300c3ba-9ddb-419b-99ab-955af99a4870"
# META         }
# META       ]
# META     }
# META   }
# META }

# CELL ********************

from pyspark.sql import functions as F
from pyspark.sql.types import IntegerType

# 1. Read all raw Parquet files inside Files/raw/sales
raw_df = (
    spark.read
    .option("recursiveFileLookup", "true")
    .parquet("Files/raw/sales")
)

print(f"Raw record count: {raw_df.count()}")

# 2. Clean, filter invalid rows, and standardize columns (using exact camelCase source names)
silver_sales_df = (
    raw_df
    .filter(F.col("totalAmount") > 0)                      # Remove zero/negative fares
    .filter(F.col("tripDistance") > 0)                     # Remove invalid zero-distance rows
    .dropna(subset=["lpepPickupDatetime", "totalAmount"])  # Drop records missing critical fields
    .withColumn("pickup_date", F.to_date("lpepPickupDatetime"))
    .withColumn("pickup_year", F.year("lpepPickupDatetime"))
    .withColumn("pickup_month", F.month("lpepPickupDatetime"))
    # Map Location to synthetic CustomerIDs (101-105) so we can join with bronze_customers later
    .withColumn("CustomerID", ((F.abs(F.hash(F.col("puLocationId"))) % 5) + 101).cast(IntegerType()))
    .select(
        "CustomerID",
        F.col("vendorID").alias("VendorID"),
        "pickup_date",
        "pickup_year",
        "pickup_month",
        F.col("passengerCount").alias("passenger_count"),
        F.col("tripDistance").alias("trip_distance"),
        F.col("fareAmount").alias("fare_amount"),
        F.col("tipAmount").alias("tip_amount"),
        F.col("totalAmount").alias("total_amount"),
        F.col("paymentType").alias("payment_type")
    )
    .dropDuplicates()
)

# 3. Enable V-Order & Write as a Managed Delta Table in the Silver layer
spark.conf.set("spark.sql.parquet.vorder.enabled", "true")

(
    silver_sales_df.write
    .format("delta")
    .mode("overwrite")
    .option("overwriteSchema", "true")
    .saveAsTable("silver_sales")
)

print("Successfully created managed Delta table: silver_sales!")


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

from pyspark.sql.types import StructType, StructField, IntegerType, StringType

# 1. Create clean silver_customers table (matching CustomerIDs 101-105 mapped in silver_sales)
customers_data = [
    (101, "Aarav Sharma", "Chennai", "Gold"),
    (102, "Priya Patel", "Bengaluru", "Platinum"),
    (103, "Rohan Verma", "Mumbai", "Silver"),
    (104, "Ananya Iyer", "Hyderabad", "Gold"),
    (105, "Vikram Nair", "Delhi", "Platinum")
]

customers_schema = StructType([
    StructField("CustomerID", IntegerType(), False),
    StructField("CustomerName", StringType(), True),
    StructField("City", StringType(), True),
    StructField("LoyaltyTier", StringType(), True)
])

silver_customers_df = spark.createDataFrame(customers_data, schema=customers_schema)

(
    silver_customers_df.write
    .format("delta")
    .mode("overwrite")
    .option("overwriteSchema", "true")
    .saveAsTable("silver_customers")
)

print("Tables currently in Lakehouse:", [t.name for t in spark.catalog.listTables()])


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# 1. Preview rows in both Silver tables
print("--- silver_customers ---")
display(spark.table("silver_customers"))

print("--- silver_sales (Top 5 rows) ---")
display(spark.table("silver_sales").limit(5))

# 2. Verify Delta Lake history (confirms WRITE + OPTIMIZE/ZORDER succeeded)
print("--- Delta History for silver_sales ---")
display(spark.sql("DESCRIBE HISTORY silver_sales").select("version", "timestamp", "operation", "operationMetrics"))


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
