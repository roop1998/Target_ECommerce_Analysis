### `Problem_Statement.md`
```markdown
# Problem Statement

Assuming you are a data analyst/scientist at Target, you have been assigned the task of analyzing the given dataset to extract valuable insights and provide actionable recommendations.

## What does "good" look like?
Import the dataset and do usual exploratory analysis steps like checking the structure & characteristics of the dataset:
- Data type of all columns in the "customers" table.
- Get the time range between which the orders were placed.
- Count the Cities & States of customers who ordered during the given period.

## In-depth Exploration:
1. Is there a growing trend in the number of orders placed over the past years?
2. Can we see monthly seasonality in the number of orders being placed?
3. During what time of the day do Brazilian customers mostly place their orders?
   - 0-6 hrs : Dawn
   - 7-12 hrs: Morning
   - 13-18 hrs: Afternoon
   - 19-23 hrs: Night

## Evolution of E-commerce orders in the Brazil region:
- Get the month-on-month number of orders placed in each state.
- How are customers distributed across all the states?

## Impact on Economy:
- Get the % increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only).
  - Use `payment_value` from `payments` table as order cost.
- Calculate the Total & Average value of order price for each state.
- Calculate the Total & Average value of order freight for each state.

## Analysis based on sales, freight and delivery time:
- Find the number of days taken to deliver each order from the purchase date (time_to_deliver).
- Calculate the difference (in days) between the estimated & actual delivery date (diff_estimated_delivery) — do this in a single query.
  - `time_to_deliver = order_delivered_customer_date - order_purchase_timestamp`
  - `diff_estimated_delivery = order_delivered_customer_date - order_estimated_delivery_date`
- Find top 5 states with highest & lowest average freight value.
- Find top 5 states with highest & lowest average delivery time.
- Find top 5 states where order delivery is faster compared to estimated date.

## Analysis based on payments:
- Month-on-month number of orders placed using different payment types.
- Number of orders placed by payment_installments.
