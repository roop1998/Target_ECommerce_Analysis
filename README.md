## README.md

# Target Brazil E-commerce Data Analysis (2016-2018)

This project analyzes Target’s e-commerce operations in Brazil using a dataset of 100,000+ orders spanning 2016–2018. The analysis explores customer behavior, sales trends, payment patterns, and delivery performance across multiple regions.

### Dataset Overview

The dataset contains 8 tables:

* **customers**: Customer details (ID, location)
* **orders**: Order timestamps and status
* **products**: Product attributes and dimensions
* **sellers**: Seller location details
* **payments**: Payment types, installments, and amounts
* **geolocation**: Zip code and latitude/longitude info
* **order_items**: Items per order with price and freight
* **order_reviews**: Customer reviews and scores

**Time period covered:** September 2016 – October 2018

---

### Key Analyses & Insights

#### 1. Sales Trends

* Peak sales months: **Oct–Dec**, correlating with festive and Black Friday season.
* E-commerce shows slight decline after January 2018 compared to 2017.
* Customers prefer shopping **10 AM – 5 PM**, with another minor peak 8–10 PM.

#### 2. Regional Insights

* **SP state** contributes 42% of total orders; **RR state** has the least.
* Distribution of orders by state shows the concentration of customers in major urban centers.

#### 3. Delivery & Freight

* Higher freight charges correlate with longer delivery times (e.g., **RR, AC**).
* Top 5 states with fastest deliveries: **AL, MA, SE, SP, BA**.
* Top 5 states with slowest deliveries: **AC, RO, AM, AP, RR**.

#### 4. Payment Analysis

* **Credit card** is the most preferred payment type, followed by **UPI, voucher, debit card**.
* Most customers pay in **1 installment**; extended installments are rare.

#### 5. Economic Impact

* Month-over-month analysis shows increase in **order payments** from 2017 to 2018 (Jan–Aug).
* Sum and average of **price and freight** reveal regions with higher e-commerce spending.

#### 6. Delivery Performance

* Calculated **time_to_delivery** (purchase → actual delivery) and **diff_estimated_delivery** (estimated → actual).
* Negative values indicate actual delivery lagged behind purchase date; positive values indicate early deliveries.

---

### Technical Details

* SQL queries were executed on **BigQuery** for aggregation, joins, and timestamp calculations.
* Metrics computed include:

  * Monthly order trends
  * Hourly sales distribution
  * Regional order distributions
  * Payment type analysis
  * Freight and delivery performance

---

### Visualizations

* Monthly sales trend charts
* Hourly order distribution charts
* Maps of orders by state
* Delivery performance vs. freight value

*(Charts are saved in `charts/` folder as PNG files.)*

---

### Insights & Recommendations

* Offer **discounts during high-sales months** to maximize revenue.
* Consider **lowering freight charges** or **optimizing delivery for remote states** to improve customer experience.
* Incentivize **credit card users** to increase repeat purchases.
* Monitor **high-freight regions** to explore warehouse expansion or logistics optimization.

---

### Next Steps

* Predictive modeling for **demand forecasting**.
* Clustering customers for **personalized marketing**.
* Anomaly detection for **delivery delays**.
