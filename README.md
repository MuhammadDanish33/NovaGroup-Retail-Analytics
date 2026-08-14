# NovaGroup Retail Analytics — SQL Portfolio Project

End-to-end SQL analysis of a fictional multi-location retailer, covering sales performance, inventory health, supply chain fulfilment, and executive-level KPI reporting on a star-schema data warehouse.

## Why this project

Retailers make decisions across three interlocking problems: **what's selling**, **what's in stock**, and **what's on order**. This project answers all three using a single T-SQL / SQL Server database (`NovaGroup`) built on a standard fact/dimension model — the same pattern you'd find in a real BI or data warehouse environment.

## Data model

| Schema | Table | Grain |
|---|---|---|
| Retail | `FactSalesLine` | one row per line item sold |
| Retail | `FactInventorySnapshot` | one row per product/location/date snapshot |
| Retail | `FactPurchaseOrderLine` | one row per PO line item |
| Retail | `FactGoodsReceipt` | one row per received shipment line |
| Retail | `FactReturnLine` | one row per returned unit |
| Retail | `DimProduct`, `DimLocation`, `DimChannel` | descriptive attributes |
| Common | `DateDim` | calendar dimension |

## Business questions answered

1. **Sales trends** — monthly units, revenue, and profit trajectory
2. **Category performance** — revenue and profit by product category
3. **Product margin** — which SKUs are actually profitable, not just high-revenue
4. **Store & channel performance** — where and how customers are buying
5. **Slow-moving inventory** — products with no sales in 30+ days
6. **Inventory value & health** — capital tied up by location; stockout/overstock flags
7. **Discounting impact** — which products are discounted most and whether it pays off
8. **Open purchase orders** — outstanding supplier commitments and their value
9. **Return rates** — which categories get returned most
10. **Replenishment risk** — fast movers at risk of stocking out
11. **Overstock detection** — capital sitting idle in slow-moving stock
12. **Supplier fulfilment** — which suppliers under-deliver against orders
13. **Top/bottom revenue products**
14. **Executive KPI summary** — one-row snapshot of the whole business

## Key SQL techniques demonstrated

- Multi-table joins across fact and dimension tables (INNER, LEFT)
- Aggregation with `GROUP BY` / `HAVING`
- Scalar and correlated subqueries
- Common Table Expressions (CTEs) to avoid repeated subqueries
- `CASE` expressions for business rule classification (stockout risk, replenishment status)
- Safe division with `NULLIF` to avoid divide-by-zero errors
- Pre-aggregating before joining to avoid join fan-out (see note below)

## How to run

1. Restore/point at a SQL Server instance with the `NovaGroup` database (schema above).
2. Run `retail_analytics_queries.sql` — each section is self-contained and commented with the business question it answers.
3. (Optional) Export results to CSV and visualize in Power BI / Tableau / Excel — see "Next steps."

## Skills demonstrated

`SQL Server / T-SQL` · `Joins` · `Aggregation` · `Subqueries` · `CTEs` · `CASE logic` · `Star schema data modeling` · `Retail/inventory domain knowledge`

---
*Fictional dataset built for portfolio/learning purposes.*
