# 👟 Sportswear Store – SQL Sales Analysis

SQL case study on a **synthetic** sportswear retailer. The goal is to answer 8 business questions with simple SQL and turn the results into actions that can **increase profit**.

The project has two main files: the SQL script with all the queries, and this README with the results and insights.

## 🗂 Project Structure
```
```
sql.1/
│
├── customers.csv
├── products.csv
├── orders.csv
└── order_items.csv
│
├── sportswear_sql_analysis.sql
└── README.md

## 🛠 Tools Used
| Tool | Purpose |
|---|---|
| SQL (SQLite) | Tables, views, joins, aggregations |
| Python (pandas) / Google Colab | Loading the CSV files and running the queries |
| CSV files | Raw data |

## 🧱 Data
The data is **synthetic** (fictional) and was created for practice. It does not describe any real company or customer. Period: January 2024 – December 2025. Currency: EGP.

`customers` 1 ── * `orders` 1 ── * `order_items` * ── 1 `products`

| Table | Rows | Columns |
|---|---|---|
| customers | 600 | customer_id, signup_date, city, gender, age_group |
| products | 30 | product_id, product_name, category, unit_price, unit_cost |
| orders | 2,025 | order_id, customer_id, order_date, channel, payment_method, order_status, discount_pct |
| order_items | 3,783 | order_item_id, order_id, product_id, quantity, unit_price |

**Metric definitions**
- **Revenue** = quantity × unit_price × (1 − discount_pct / 100), on **Completed** orders only.
- **Cost** = quantity × unit_cost.
- **Profit** = Revenue − Cost. **Margin** = Profit ÷ Revenue.

**Data notes**
- 18 customers have no city. City names are not consistent in casing, so `LOWER()` is used when grouping by city.
- Cancelled and returned orders are excluded from revenue and profit.
- Item prices in 2025 are higher than in 2024, so revenue uses `order_items.unit_price` (the price at the time of sale).

## ✅ Data Checks
```sql
-- Check 1: number of rows in each table
SELECT 'customers' AS table_name, COUNT(*) AS total_rows FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items;
```

| table_name | total_rows |
|---|---|
| customers | 600 |
| products | 30 |
| orders | 2025 |
| order_items | 3783 |

Customers with a missing city: **18**. Orders by status: Completed 1,831, Cancelled 95, Returned 99.

## 📝 Business Questions and Insights

Total over the two years: **revenue 2,834,909** and **profit 1,181,870** (margin 41.7%).

### Q1. Which categories bring the highest profit and the best margin?
```sql
-- Q1) Which categories bring the highest profit and the best margin?
SELECT category,
       ROUND(SUM(revenue)) AS revenue,
       ROUND(SUM(revenue - cost)) AS profit,
       ROUND(100.0 * SUM(revenue - cost) / SUM(revenue), 1) AS margin_pct
FROM v_sales
WHERE order_status = 'Completed'
GROUP BY category
ORDER BY profit DESC;
```

| category | revenue | profit | margin_pct |
|---|---|---|---|
| Running Shoes | 616,725 | 242,106 | 39.3 |
| Hoodies & Jackets | 445,987 | 178,633 | 40.1 |
| Training Shoes | 425,223 | 172,615 | 40.6 |
| T-Shirts | 360,557 | 150,940 | 41.9 |
| Leggings | 320,305 | 150,817 | 47.1 |
| Bags & Equipment | 242,561 | 115,821 | 47.7 |
| Shorts | 212,433 | 86,720 | 40.8 |
| Socks & Accessories | 211,116 | 84,218 | 39.9 |

**Insight:** Running Shoes bring the most profit (242,106, about 20% of total profit) but have one of the lowest margins (39.3%). Bags & Equipment (47.7%) and Leggings (47.1%) have the best margins and together bring about 23% of profit.

**Action:** Promote leggings and bags next to shoes (cross-selling), and review prices and costs for Running Shoes and Socks & Accessories.

### Q2. Which products bring the most and the least profit?

**Top 10 products by profit**
```sql
-- Q2a) Top 10 products by profit
SELECT product_name,
       category,
       SUM(quantity) AS units_sold,
       ROUND(SUM(revenue - cost)) AS profit,
       ROUND(100.0 * SUM(revenue - cost) / SUM(revenue), 1) AS margin_pct
FROM v_sales
WHERE order_status = 'Completed'
GROUP BY product_name, category
ORDER BY profit DESC
LIMIT 10;
```

| product_name | category | units_sold | profit | margin_pct |
|---|---|---|---|---|
| Gym Flex | Training Shoes | 70 | 70,338 | 50.7 |
| Trail Grip | Running Shoes | 55 | 66,394 | 44.2 |
| Seamless Leggings | Leggings | 153 | 65,485 | 50.8 |
| Road Runner Pro | Running Shoes | 58 | 64,114 | 37.3 |
| Light Racer | Running Shoes | 75 | 60,976 | 36.2 |
| Padded Jacket | Hoodies & Jackets | 65 | 58,429 | 44.5 |
| Court Low | Training Shoes | 90 | 54,744 | 38.2 |
| Gym Duffel Bag | Bags & Equipment | 126 | 54,122 | 51.1 |
| Daily Trainer | Running Shoes | 74 | 50,623 | 40.1 |
| Cross Trainer X | Training Shoes | 62 | 47,533 | 33.2 |

**Insight:** Gym Flex is the top product (70,338 profit from only 70 units), and Seamless Leggings brings 65,485 with a 50.8% margin.

**Bottom 5 products by profit**
```sql
-- Q2b) Bottom 5 products by profit
SELECT product_name,
       category,
       SUM(quantity) AS units_sold,
       ROUND(SUM(revenue - cost)) AS profit,
       ROUND(100.0 * SUM(revenue - cost) / SUM(revenue), 1) AS margin_pct
FROM v_sales
WHERE order_status = 'Completed'
GROUP BY product_name, category
ORDER BY profit ASC
LIMIT 5;
```

| product_name | category | units_sold | profit | margin_pct |
|---|---|---|---|---|
| Headband | Socks & Accessories | 356 | 9,176 | 34.9 |
| Sport Socks 3-Pack | Socks & Accessories | 250 | 11,731 | 33.7 |
| Sweat Wristbands | Socks & Accessories | 364 | 14,843 | 48.4 |
| Water Bottle | Bags & Equipment | 276 | 18,348 | 39.5 |
| Cap | Socks & Accessories | 249 | 22,625 | 38.4 |

**Insight:** Four of the five least profitable products are Socks & Accessories, and the fifth is the Water Bottle. They sell many units (249 to 364 each) but earn little: Headband made only 9,176 from 356 units. High volume does not mean high profit.

**Action:** Protect stock of the top profit products. Sell low profit accessories as add-ons or bundles, and review the price of Headband and Sport Socks (margins 34.9% and 33.7%).

### Q3. What are the monthly revenue, profit and margin? Is there seasonality?
```sql
-- Q3) Monthly revenue, profit and margin (seasonality)
SELECT order_month,
       COUNT(DISTINCT order_id) AS orders,
       ROUND(SUM(revenue)) AS revenue,
       ROUND(SUM(revenue - cost)) AS profit,
       ROUND(100.0 * SUM(revenue - cost) / SUM(revenue), 1) AS margin_pct
FROM v_sales
WHERE order_status = 'Completed'
GROUP BY order_month
ORDER BY order_month;
```

| order_month | orders | revenue | profit | margin_pct |
|---|---|---|---|---|
| 2024-01 | 53 | 87,017 | 35,047 | 40.3 |
| 2024-02 | 51 | 59,239 | 22,893 | 38.6 |
| 2024-03 | 49 | 77,941 | 32,056 | 41.1 |
| 2024-04 | 60 | 89,968 | 34,796 | 38.7 |
| 2024-05 | 61 | 86,101 | 33,546 | 39.0 |
| 2024-06 | 55 | 77,482 | 31,025 | 40.0 |
| 2024-07 | 54 | 94,302 | 37,947 | 40.2 |
| 2024-08 | 69 | 103,707 | 40,960 | 39.5 |
| 2024-09 | 59 | 99,324 | 40,202 | 40.5 |
| 2024-10 | 72 | 106,824 | 42,803 | 40.1 |
| 2024-11 | 116 | 153,103 | 56,146 | 36.7 |
| 2024-12 | 99 | 156,462 | 63,644 | 40.7 |
| 2025-01 | 75 | 125,284 | 56,043 | 44.7 |
| 2025-02 | 95 | 140,027 | 60,378 | 43.1 |
| 2025-03 | 93 | 153,949 | 65,775 | 42.7 |
| 2025-04 | 87 | 152,656 | 67,249 | 44.1 |
| 2025-05 | 74 | 89,224 | 38,293 | 42.9 |
| 2025-06 | 65 | 82,762 | 36,776 | 44.4 |
| 2025-07 | 59 | 87,620 | 38,648 | 44.1 |
| 2025-08 | 62 | 110,324 | 48,006 | 43.5 |
| 2025-09 | 74 | 122,805 | 53,785 | 43.8 |
| 2025-10 | 104 | 164,730 | 71,667 | 43.5 |
| 2025-11 | 150 | 231,192 | 94,788 | 41.0 |
| 2025-12 | 95 | 182,867 | 79,396 | 43.4 |

**Insight:** November is the peak month: orders jump from 72 to 116 (+61%) in 2024 and from 104 to 150 (+44%) in 2025. But the margin drops in November (36.7% in 2024 against about 40% in nearby months, and 41.0% in 2025 against 43 to 44%). In 2024 the busiest month was not the most profitable: December made more profit (63,644) than November (56,146) with fewer orders. Overall, revenue grew from about 1.19M in 2024 to 1.64M in 2025 (+38%).

**Are November orders discounted more?**
```sql
-- Q3b) Are November orders discounted more than other months?
SELECT CASE WHEN strftime('%m', order_date) = '11' THEN 'November' ELSE 'Other months' END AS period,
       COUNT(*) AS orders,
       ROUND(100.0 * SUM(CASE WHEN discount_pct > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS discounted_orders_pct
FROM orders
WHERE order_status = 'Completed'
GROUP BY period;
```

| period | orders | discounted_orders_pct |
|---|---|---|
| November | 266 | 38.7 |
| Other months | 1565 | 20.3 |

**Insight:** 38.7% of November orders carry a discount, against 20.3% in other months. This explains the margin drop in the peak month.

**Action:** Keep the November campaign, but limit discounts to small percentages on best sellers instead of discounting widely.

### Q4. Who are the top 10 customers by amount spent?
```sql
-- Q4) Top 10 customers by amount spent
SELECT customer_id,
       COUNT(DISTINCT order_id) AS orders,
       ROUND(SUM(revenue)) AS amount_spent,
       ROUND(SUM(revenue - cost)) AS profit
FROM v_sales
WHERE order_status = 'Completed'
GROUP BY customer_id
ORDER BY amount_spent DESC
LIMIT 10;
```

| customer_id | orders | amount_spent | profit |
|---|---|---|---|
| 25 | 28 | 52,537 | 21,751 |
| 4 | 25 | 49,032 | 18,690 |
| 325 | 23 | 44,882 | 18,463 |
| 34 | 23 | 39,633 | 17,639 |
| 148 | 22 | 33,070 | 12,981 |
| 388 | 19 | 31,782 | 13,686 |
| 111 | 16 | 30,462 | 12,838 |
| 413 | 12 | 29,716 | 12,625 |
| 219 | 17 | 29,174 | 12,362 |
| 474 | 12 | 28,992 | 12,276 |

**Insight:** The top 10 customers (out of 600 registered) bring about 13% of total revenue (369K of 2.83M). Customer 25 alone placed 28 orders and spent 52,537. Each of the top 10 placed between 12 and 28 orders.

**Action:** Create a loyalty tier or early access for repeat buyers, and make sure these customers do not face cancellations or returns.

### Q5. How does the discount level affect margin and profit?
```sql
-- Q5) How does the discount level affect margin and profit?
SELECT discount_pct,
       COUNT(DISTINCT order_id) AS orders,
       ROUND(SUM(revenue - cost)) AS profit,
       ROUND(100.0 * SUM(revenue - cost) / SUM(revenue), 1) AS margin_pct
FROM v_sales
WHERE order_status = 'Completed'
GROUP BY discount_pct
ORDER BY discount_pct;
```

| discount_pct | orders | profit | margin_pct |
|---|---|---|---|
| 0 | 1,410 | 994,102 | 43.7 |
| 10 | 241 | 129,280 | 37.3 |
| 20 | 128 | 48,100 | 29.9 |
| 30 | 52 | 10,388 | 19.8 |

**Insight:** Orders with no discount are 77% of completed orders and bring 84% of profit (margin 43.7%). Margin falls sharply as the discount grows: 37.3% at 10%, 29.9% at 20% and only 19.8% at 30%. The 52 orders with a 30% discount brought just 10,388 profit (0.9% of the total).

**Action:** Stop 30% and 20% discounts, and test 10% offers only where the margin allows it.

### Q6. Which payment methods have the most cancelled and returned orders, and how much revenue is lost?
```sql
-- Q6a) Orders by payment method and status (cancelled and returned)
SELECT payment_method,
       order_status,
       COUNT(*) AS orders
FROM orders
GROUP BY payment_method, order_status
ORDER BY payment_method, order_status;
```

| payment_method | order_status | orders |
|---|---|---|
| Card | Cancelled | 39 |
| Card | Completed | 878 |
| Card | Returned | 41 |
| Cash | Cancelled | 6 |
| Cash | Completed | 315 |
| Cash | Returned | 8 |
| Cash on Delivery | Cancelled | 28 |
| Cash on Delivery | Completed | 325 |
| Cash on Delivery | Returned | 27 |
| Installments | Cancelled | 10 |
| Installments | Completed | 105 |
| Installments | Returned | 12 |
| Wallet | Cancelled | 12 |
| Wallet | Completed | 208 |
| Wallet | Returned | 11 |

```sql
-- Q6b) Revenue by order status (how much revenue is lost)
SELECT order_status,
       ROUND(SUM(revenue)) AS revenue
FROM v_sales
GROUP BY order_status;
```

| order_status | revenue |
|---|---|
| Cancelled | 135,337 |
| Completed | 2,834,909 |
| Returned | 151,429 |

**Insight:** Cancelled plus returned orders as a share of all orders by payment method: Installments 17.3% (22 of 127), Cash on Delivery 14.5% (55 of 380), Wallet 10.0%, Card 8.4% and Cash 4.3%. Cancelled and returned orders represent 286,766 of revenue, about 10% of the completed revenue.

**Action:** Confirm Cash on Delivery orders by phone before shipping, and review how installment orders are approved.

### Q7. Which cities bring the highest profit?
```sql
-- Q7) Which cities bring the highest profit?
SELECT LOWER(c.city) AS city,
       COUNT(DISTINCT s.order_id) AS orders,
       ROUND(SUM(s.revenue - s.cost)) AS profit
FROM v_sales s
JOIN customers c ON c.customer_id = s.customer_id
WHERE s.order_status = 'Completed'
  AND c.city IS NOT NULL
GROUP BY LOWER(c.city)
ORDER BY profit DESC;
```

| city | orders | profit |
|---|---|---|
| cairo | 675 | 430,950 |
| alexandria | 279 | 177,421 |
| giza | 265 | 168,501 |
| assiut | 126 | 87,467 |
| mansoura | 107 | 72,171 |
| port said | 99 | 64,854 |
| tanta | 87 | 50,321 |
| suez | 56 | 38,699 |
| luxor | 45 | 29,205 |
| ismailia | 39 | 23,067 |

**Insight:** Cairo alone brings 36% of profit, and Cairo, Alexandria and Giza together bring about 66%. Assiut is fourth with 126 orders, ahead of larger looking cities such as Mansoura. The 18 customers with no city are excluded, so these totals cover most but not all profit.

**Action:** Keep investing in the top three cities, and test local campaigns in Assiut and Mansoura.

### Q8. Online or Store: which channel brings more profit?
```sql
-- Q8) Online vs Store
SELECT channel,
       COUNT(DISTINCT order_id) AS orders,
       ROUND(SUM(revenue)) AS revenue,
       ROUND(SUM(revenue - cost)) AS profit
FROM v_sales
WHERE order_status = 'Completed'
GROUP BY channel
ORDER BY profit DESC;
```

| channel | orders | revenue | profit |
|---|---|---|---|
| Online | 1077 | 1,648,844 | 681,925 |
| Store | 754 | 1,186,065 | 499,945 |

**Insight:** Online brings more profit overall (681,925, 58% of the total) because it has more orders (1,077 against 754). But each store order earns about 5% more profit than an online order (about 663 against 633).

**Action:** Keep growing online, and raise the online basket size with bundles or a free shipping threshold.

## 🎯 Recommendations Summary
1. **Reduce deep discounts.** Discounts of 20% and 30% bring almost no profit (Q5), and heavy November discounts lower the margin in the best month (Q3).
2. **Push high margin categories.** Leggings and Bags & Equipment have the best margins (Q1), so sell them with shoes.
3. **Do not confuse volume with profit.** Cheap accessories sell many units but earn little, so use them as add-ons and review their prices (Q2).
4. **Fix cancellations and returns.** Installments and Cash on Delivery have the highest problem rates, and about 10% of revenue is lost (Q6).
5. **Protect the best customers and cities.** 10 customers bring 13% of revenue and 3 cities bring 66% of profit (Q4, Q7).

Ahmed Noby /// DATA ANALYSIS
