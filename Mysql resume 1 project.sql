-- 1.
--  Provide the list of markets in which customer 
-- "Atliq Exclusive" operates its business in the APAC region.

select  
        distinct market 
from dim_customer
where customer = "Atliq Exclusive" and region = "APAC";



-- 2.
-- What is the percentage of unique product increase in 2021 vs 2020?
-- The final output contains these fields,
-- unique_products_2020
-- unique_products_2021
-- percentage_chg

with cte1 as (
             SELECT count(distinct 
				case 
                     when fiscal_year =2020 then product_code 
				end ) as unique_products_2020,
                    count(distinct 
				case 
                     when fiscal_year =2021 then product_code 
				end ) as unique_products_2021         
				from fact_sales_monthly)
     select  *,
     round(((unique_products_2021 - unique_products_2020)/unique_products_2020)*100,2) as percentage_chg
	 from cte1;
     
     
 -- 3.    
-- Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts. The final output contains
-- 2 fields = segment , product_count
     
 
select segment,
     count(distinct product_code) as product_count
     from dim_product
     group by segment
     order by product_count desc;
     
     
-- 4.     
-- Follow-up: Which segment had the most increase in unique products in
-- 2021 vs 2020? The final output contains these fields, 
-- segment
-- product_count_2020
-- product_count_2021  
-- difference     
     

with cte1 as (
             SELECT p.segment,
         count(distinct 
				case 
                     when s.fiscal_year =2020 then product_code 
				end ) as unique_products_2020,
	     count(distinct 
				case 
                     when s.fiscal_year =2021 then product_code 
				end ) as unique_products_2021         
				from dim_product p
                join fact_sales_monthly s
                using ( product_code )
                group by segment)
     select *,
      (unique_products_2021 - unique_products_2020) as difference  
     from cte1
     order by difference  desc ;
                
 

-- 5.
-- Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields, 
-- product_code ,
-- product      ,
-- manufacturing_cost
 
 
(SELECT product_code,
         p.segment,
	   p.product,
       m.manufacturing_cost
FROM fact_manufacturing_cost m
join dim_product p
using( product_code)
order by m.manufacturing_cost asc
limit 1)

union 

(SELECT product_code,
        p.segment,
	   p.product,
       m.manufacturing_cost
FROM fact_manufacturing_cost m
join dim_product p
using(product_code)
order by m.manufacturing_cost desc 
limit 1);


-- 6.
-- Generate a report which contains the top 5 customers who received an
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields, 
-- customer_code ,
-- customer,
-- average_discount_percentage 

select 
	   c.customer_code,
       c.customer,
	   round(avg(pre.pre_invoice_discount_pct)*100,2) as average_discount_percentage 
from dim_customer c
join fact_pre_invoice_deductions pre
using ( customer_code ) 
where fiscal_year =2021 and c.market = "india" 
group by  c.customer_code, c.customer
ORDER BY average_discount_percentage  DESC
limit 5;



-- 7.
-- Get the complete report of the Gross sales amount for the customer “Atliq
-- Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.
-- The final report contains these columns:
-- Month
-- Year
-- Gross sales Amount


select   
	     monthname(min(date)) as month,
         year(min(date)) as year,
         round(sum(s.sold_quantity * g.gross_price),2) as Gross_sales_Amount
from fact_sales_monthly s
join dim_customer c
on s.customer_code = c.customer_code
join fact_gross_price g
on s.product_code = g.product_code and 
   s.fiscal_year = g.fiscal_year 
where c.customer = "Atliq Exclusive" 
AND YEAR(date) BETWEEN 2019 AND 2021
group by year(date), month(date)
order by year , month(date) asc;





-- 8.
-- In which quarter of 2020, got the maximum total_sold_quantity? The final
-- output contains these fields sorted by the total_sold_quantity,
-- Quarter
-- total_sold_quantity


select    
         case
               when month(date) in (9,10,11) then "Q1"
               when month(date) in (12,1,2) then "Q2"
               when month(date) in (3,4,5) then "Q3" 
               else "Q4"
		 end as Quarter,
	  sum(sold_quantity) as total_sold_quantity
from fact_sales_monthly 
where fiscal_year = 2020 
group by  Quarter 
order by Quarter asc;





-- 9. 
-- Which channel helped to bring more gross sales in the fiscal year 2021
-- and the percentage of contribution? The final output contains these fields,
-- channel
-- gross_sales_mln
-- percentage

   
with cte1 as (
 select 
        c.channel , 
       round(sum(s.sold_quantity * g.gross_price)/1000000,2) as gross_sales_mln
from fact_sales_monthly s
join dim_customer c
on s.customer_code = c.customer_code
join fact_gross_price g
on s.product_code = g.product_code and
   s.fiscal_year = g.fiscal_year
   where s.fiscal_year = 2021
   group by c.channel)
select 
      channel ,
	  gross_sales_mln,
       round(gross_sales_mln / sum(gross_sales_mln) over () *100 ,2) as percentage
      from cte1
      order by  gross_sales_mln desc;
      
      
      
      
-- 10.
-- Get the Top 3 products in each division that have a high
-- total_sold_quantity in the fiscal_year 2021? The final output contains these fields,

-- product_code
-- division
-- product
-- total_sold_quantity
-- rank_order  



with cte1 as (
             select 
       s.product_code,
       p.division,
       p.product,
       sum(s.sold_quantity) as total_sold_quantity
from fact_sales_monthly s 
join dim_product p 
on s.product_code = p.product_code 
where s.fiscal_year = 2021
group by p.product , p.division, s.product_code),

cte2 as (
      select * ,
        rank() over( partition by division order by total_sold_quantity desc ) as rnk
	  from  cte1)
select * 
from cte2 
where rnk<=3 ;   




select date_format(date,'%M') as month , year(date) as year,
round(sum(gross_price*sold_quantity),2) as gross_sales_amount
from(select c.customer_code , customer , date ,product_code , sold_quantity
from dim_customer c
join fact_sales_monthly s
using( customer_code) ) as j
join fact_gross_price g
using ( product_code)
where customer = "Atliq Exclusive"
group by month,year
order by month;

