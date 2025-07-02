SELECT * FROM gdb023.dim_customer;

select distinct region, market from dim_customer
where region = "APAC"  and
customer= "AtliQ Exclusive";
/*
What is the percentage of unique product increase in 2021 vs. 2020?
 The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg 
*/

with no_OF_PRODUCTS AS (SELECT 
   count(case when cost_year =2021 then m.product_code  end) as "2021_products",
     count(case when cost_year =2020 then m.product_code end) as "2020_products"
    
FROM
    Dim_product p
        JOIN
    fact_manufacturing_cost m ON p.product_code = m.product_code
)
SELECT *,
concat(round((2021_products-2020_products)*100/(2020_products),2),"%") as pct_change from no_of_products;
/* 3rd Question
Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
 The final output contains 2 fields, segment product_count
 */
 SELECT 
    segment, COUNT(DISTINCT product_code) AS producs_count
FROM
    dim_product
GROUP BY segment
ORDER BY 2 DESC;
 
 /* question 4
  Follow-up: 
  Which segment had the most increase in unique products in 2021 vs 2020?
  The final output contains these fields, segment product_count_2020 product_count_2021 difference
  */
  
  with no_OF_PRODUCTS AS (SELECT segment,
   count(case when cost_year =2021 then m.product_code  end) as "2021_products",
     count(case when cost_year =2020 then m.product_code end) as "2020_products"
    
FROM
    Dim_product p
        JOIN
    fact_manufacturing_cost m ON p.product_code = m.product_code
    group by segment
)
SELECT *,
(2021_products-2020_products) as difference from no_of_products
order by difference desc;


/* 5th Question
5. Get the products that have the highest and lowest manufacturing costs. 
The final output should contain these fields, product_code product manufacturing_cost
*/

with cte as (
select product_code ,manufacturing_cost from fact_manufacturing_cost where 
manufacturing_cost = (
 select  min(manufacturing_cost) as manufacturing_cost
from fact_manufacturing_cost)
union
select product_code ,manufacturing_cost from fact_manufacturing_cost where 
manufacturing_cost = (
select max(manufacturing_cost) as manufacturing_cost
from fact_manufacturing_cost)
)
select c.product_code,p.product,c.manufacturing_cost
from cte c join dim_product p 
on p.product_code=c.product_code
;

WITH MinMaxCost AS (
    SELECT product_code, manufacturing_cost
    FROM fact_manufacturing_cost
    WHERE manufacturing_cost = (
        SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost
    )
    OR manufacturing_cost = (
        SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost
    )
)

SELECT 
    c.product_code,
    p.product,
    p.category,
    c.manufacturing_cost
FROM 
    MinMaxCost c
JOIN 
    dim_product p ON p.product_code = c.product_code;
   /* 
Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct
 for the fiscal year 2021 and in the Indian market.
 The final output contains these fields, customer_code customer average_discount_percentage
 */

 select t.customer_code,c.customer, round((avg(pre_invoice_discount_pct)*100),2) as avg_disc from fact_pre_invoice_deductions t
 join dim_customer C
  on c.customer_code = t.customer_code
  where fiscal_year =2021
  and  market = "india"
 group by customer_code,2
 order by avg_disc desc
  limit 5;
  /* 7th Question
 Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month .
 This analysis helps to get an idea of low and high-performing months and take strategic decisions.\
 The final report contains these columns: Month Year Gross sales Amount 
 */
 SELECT 
    CONCAT(MONTHNAME(date), "-", YEAR(date)) AS month_year,
    f.fiscal_year,
    ROUND(SUM(f.sold_quantity * p.gross_price) / 1000000, 2) AS gross_sales
FROM 
    fact_sales_monthly f
JOIN 
    fact_gross_price p 
    ON f.product_code = p.product_code 
    AND f.fiscal_year = p.fiscal_year
JOIN 
    dim_customer c 
    ON f.customer_code = c.customer_code
WHERE 
    c.customer = "Atliq Exclusive"
GROUP BY 
    month_year, f.fiscal_year;
    
    /* 8th question
In which quarter of 2020, got the maximum total_sold_quantity? 
The final output contains these fields sorted by the total_sold_quantity, 
Quarter total_sold_quantity
 */

     with cte as( select adddate(DATE,INTERVAL 4 MONTH) AS DATE_ ,
     concat("Q",Quarter(adddate(DATE,INTERVAL 4 MONTH))) AS Quarter_, 
     fiscal_year,sum(sold_quantity) as total_sold_quantity
 from fact_sales_monthly
 where fiscal_year =2020
 group by 1,2)
 select Quarter_ as'Quarter',
 fiscal_year,
 round((sum(total_sold_quantity)/1000000),2) as Total_quantity
 from cte
 group by 1,2
 ;
 
  /*Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
  The final output contains these fields, channel gross_sales_mln percentage
  */
 WITH CHANNEL_GROSS_SALES AS ( SELECT 
   c.channel,
    ROUND(SUM(f.sold_quantity * p.gross_price) / 1000000, 2) AS gross_sales
   
FROM 
    fact_sales_monthly f
JOIN 
    fact_gross_price p 
    ON f.product_code = p.product_code 
    AND f.fiscal_year = p.fiscal_year
JOIN 
    dim_customer c 
    ON f.customer_code = c.customer_code
WHERE 
    f.fiscal_year = 2021
    GROUP BY 1
)
SELECT CHANNEL,CONCAT(ROUND(GROSS_SALES*100/SUM(GROSS_SALES) OVER(),2),"%") AS PCT_CONTRIBUTION FROM CHANNEL_GROSS_SALES
;
/*
Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
 The final output contains these fields, division product_code */
 
 with cte as (SELECT P.DIVISION,f.product_code,
 P.PRODUCT,
 SUM(SOLD_QUANTITY) AS TOTAL_QUANTITY
 FROM FACT_SALES_MONTHLY F
 JOIN DIM_PRODUCT P
 ON P.PRODUCT_CODE = F.PRODUCT_CODE
 WHERE FISCAL_YEAR = 2021
 GROUP BY DIVISION,PRODUCT,2),
 rank_cte as (SELECT *,
 RANK() OVER(PARTITION BY DIVISION ORDER BY TOTAL_Quantity desc) as rn
 from cte)
 select Division,product_code,product,total_quantity,rn as 'rank' from rank_cte
 where rn<=3;