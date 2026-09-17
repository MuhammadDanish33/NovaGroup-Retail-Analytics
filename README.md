# NovaGroup Retail Analytics — SQL Portfolio Project

## Project Overview

NovaGroup is a fictional multi-location UK retailer operating stores, warehouses, and fulfilment centres. This project performs an end-to-end SQL analysis of its transactional and operational data — covering sales performance, product margins, inventory health, supply chain fulfilment, and executive KPIs — using a star-schema data warehouse built on SQL Server. The purpose is to replicate the kind of structured, evidence-based retail analysis that supports commercial and operational decisions.

---

## Business Questions Answered

| Area | Questions |
|---|---|
| **Sales & Revenue** | Which months, categories, and products drive revenue and profit? How do channels compare? |
| **Product Margins** | Which individual products have the healthiest gross margins? Which are being discounted most? |
| **Inventory** | Where is capital tied up in stock? Which SKUs are at risk of stockout, slow-moving, or overstocked? |
| **Supply Chain** | What is the open purchase order liability? Which suppliers are underperforming on fulfilment? |
| **Executive KPIs** | What is the single-row business snapshot covering revenue, profit, inventory, stockouts, and open POs? |

---

## SQL Skills Demonstrated

- **JOINs** — INNER and LEFT JOIN across fact and dimension tables (sales lines, products, locations, channels, date, purchase orders, goods receipts, returns, inventory)
- **CTEs** — Common Table Expressions used to isolate the latest inventory snapshot and avoid repeating subquery logic (Queries 7, 14, 15)
- **Subqueries** — Scalar subqueries for date anchoring; table-derived subqueries to pre-aggregate goods receipts before joining to purchase order lines
- **GROUP BY / HAVING** — Aggregation to product, category, store, channel, and month level; HAVING clause to filter slow-moving products (>30 days without a sale)
- **CASE** — Conditional logic for replenishment status classification ("Re-order Now", "Monitor Closely") and inventory health flags ("Stockout", "Stockout Risk", "Healthy", "Overstock")
- **NULLIF** — Guards against divide-by-zero errors in gross margin and return rate percentage calculations
- **COALESCE** — Handles NULL receipt quantities in open purchase order and supplier fulfilment calculations
- **DATEDIFF / MAX** — Date arithmetic to calculate days elapsed since last sale
- **TOP N** — Returns top 10 and bottom 10 products by net revenue
- **Pre-aggregation** — Receipt quantities are summed in a subquery before joining to purchase order lines, preventing row fan-out

---

## Key Findings

### 1. Business Snapshot: £33.4M Revenue, £14.1M Gross Profit, £35.9M in Open Orders

The full dataset records **194,571 units sold**, **£33,402,300.51 in net revenue**, and **£14,075,530.24 in gross profit**. Current inventory on hand is valued at **£65,722.51**. Open purchase orders — stock ordered from suppliers but not yet received — total **£35,925,849.55**, exceeding the entire period's net revenue.

> **Why it matters:** An open PO pipeline larger than period revenue signals significant near-term stock liability. If sell-through doesn't keep pace with incoming goods, working capital will be under pressure.

---

### 2. Sports Leads on Both Revenue and Profit; Clothing Lags

**Sports** is the top category on both measures: **£3,971,160.06 in net sales** and **£1,798,344.31 in gross profit**. **Health & Beauty** follows at £3,828,378.74 and £1,720,946.44. **Clothing** ranks last in gross profit at **£1,057,382.83** — around 59p of profit for every £1 Sports generates — despite Automotive (£2,939,437.26) and Electronics (£2,917,406.67) generating comparable revenue in the lower half.

> **Why it matters:** Clothing's margin underperformance relative to its revenue scale warrants a review of pricing, promotions, and cost of goods. A category margin problem at this scale compounds quickly.

---

### 3. Revenue Rank Does Not Equal Profit Rank

**Toys** ranks 5th in net sales (£3,397,852.35) but 3rd in gross profit (£1,492,645.25). **Grocery** ranks 3rd in net sales (£3,528,217.08) but 5th in gross profit (£1,406,518.67). The inversion signals that Grocery's higher revenue does not translate into higher profit — likely driven by lower margin products, promotional pricing, or mix.

> **Why it matters:** Merchandise and pricing decisions should be anchored to profit contribution, not headline revenue. Investing in Toys growth returns more gross profit per pound of sales than equivalent Grocery growth.

---

### 4. All Four Channels Perform Within a Narrow Band; Store Marginally Leads

| Channel | Units Sold | Net Sales |
|---|---:|---:|
| Store | 49,470 | £8,578,367.39 |
| Mobile | 48,329 | £8,349,004.97 |
| Online | 48,775 | £8,262,387.93 |
| Marketplace | 47,997 | £8,212,540.22 |

The spread between the highest and lowest channel is £365,827 — roughly 4% of any channel's revenue.

> **Why it matters:** No single channel dominates, indicating a healthy omnichannel spread. However, Marketplace trails on both volume and revenue; a review of listing fees or commission structures may be warranted.

---

### 5. One SKU Has Not Sold in 352 Days

The slow-moving analysis identified **"Sharable coherent support" (SKU748035, Home & Garden)** as the longest-dormant product — last sold on **13 January 2025**, representing **352 days** without a transaction at the dataset reference date. Dozens of other SKUs exceed 100+ days of inactivity.

> **Why it matters:** Dead stock is a direct working capital cost. At 352 days, this SKU is a strong candidate for clearance pricing, liquidation, or delisting to free up shelf space and cash.

---

### 6. Supplier Fulfilment Ranges from 53.66% to 102.69%

Of 60 suppliers analysed, **Supplier 15** fulfilled only **53.66%** of ordered quantity (21,707 ordered, 11,647 received). Several suppliers cluster between 60–75%. **Supplier 57** records **102.69%** — suggesting a data anomaly or goods received against a previously closed order line.

> **Why it matters:** Suppliers consistently delivering below 60–65% create downstream stockout risk and disrupt replenishment planning. The 102.69% outlier also warrants investigation to confirm data integrity.

---

### 7. Two Fast-Selling SKUs Are at Critical Reorder Risk

The replenishment model (>100 units sold historically AND <5 units currently available) flagged two products as **"Re-order Now"**:

| Product | SKU | Category | Units Sold | Stock Remaining |
|---|---|---|---|---|
| Profit-focused system-worthy instruction set | SKU823323 | Sports | 152 | **1 unit** |
| Sharable impactful hierarchy | SKU538363 | Clothing | 101 | **0 units** (20 reserved) |

> **Why it matters:** Both are proven sellers now at near-zero availability. Any incoming demand for these SKUs will go unfulfilled, directly converting to lost revenue.

---

## Business Value

This analysis supports decisions across four commercial functions:

- **Buying & Merchandising** — Category and product-level margin rankings identify where to negotiate cost prices, rationalise range, or redirect promotional investment.
- **Supply Chain & Operations** — Open PO exposure, supplier fulfilment rates, slow-moving stock, and replenishment alerts enable proactive stock management and supplier accountability.
- **Commercial Finance** — The executive KPI summary provides a board-ready one-row snapshot; revenue-vs-profit divergence by category flags pricing risk.
- **Store & Channel Management** — Store-level revenue and location-level inventory health data support decisions on range allocation and replenishment priorities across 85+ locations.

---

## Tools

| Tool | Role |
|---|---|
| **SQL Server / T-SQL** | All data extraction, aggregation, and analysis (20 queries) |
| **Microsoft Excel** | Query result output and results presentation |

---

## Limitations

- **Fictional dataset.** All data is synthetic. Company names, product names, SKUs, locations, and financial figures are fabricated for portfolio demonstration purposes only. They do not represent any real business or organisation.
- **Single inventory snapshot.** Inventory queries reflect one point-in-time snapshot. Stock level trends over time are not captured.
- **Supplier names not available.** Suppliers are referenced by numeric key only; no supplier name is present in the dataset, limiting the direct commercial interpretability of fulfilment results.
- **Stockout days assumption.** The stockout days analysis assumes one inventory snapshot row per calendar day. This assumption is noted in the SQL comments and has not been independently validated.
- **No customer-level data.** The analysis covers product, category, location, and channel performance only. Customer segmentation and lifetime value are outside the scope of the available schema.

---

## Repository Structure

```
NovaGroup-Retail-Analytics/
│
├── NovaGroup Retail Analytics End-to-End SQL Reporting.sql   # 20 T-SQL analytical queries
├── NovaGroup Retail Analytics Reporting.xlsx                  # Query results across 20 worksheets
└── README.md                                                  # This file
```
