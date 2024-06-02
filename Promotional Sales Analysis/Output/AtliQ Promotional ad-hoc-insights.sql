use retail_events_db;
show tables;

select * from dim_campaigns;
select * from dim_products;
select * from dim_stores;
select * from fact_events;

-- 1. 
select distinct(dp.product_name), fe.base_price, fe.promo_type 
from dim_products as dp
join fact_events as fe
on dp.product_code = fe.product_code
where fe.base_price > 500
and promo_type = 'BOGOF';

-- 2.
select city, count(store_id) as store_count 
from dim_stores group by city 
order by store_count desc;

-- 3. Identify the top 3 stores with the highest average revenue per campaign.
-- This report should include fields such as store_name, city, average_revenue_per_campaign, 
-- helping to identify the most profitable stores during campaigns.
select ds.store_id, ds.city, concat(round(avg(base_price * `quantity_sold(after_promo)`)/1000000,3),'M') 
as average_revenue_per_campaign
from dim_stores as ds
join fact_events as fe
on ds.store_id = fe.store_id
group by ds.store_id, ds.city
order by average_revenue_per_campaign desc
limit 3;

-- 4. Determine the campaign with the highest total quantity sold across all stores.
-- This report will include campaign_name, total_quantity_sold, and campaign_start_date, providing insights 
-- into the most successful campaigns in terms of sales volume.
select dc.campaign_id, dc.campaign_name, sum(`quantity_sold(after_promo)`) as total_quantity_sold, dc.start_date
from dim_campaigns as dc
join fact_events as fe
on dc.campaign_id = fe.campaign_id
group by dc.campaign_id
order by total_quantity_sold desc;
 
 
 -- 5. List the top 5 cities by total number of unique products sold.
 -- This report will include city, total_unique_products_sold, and total_sales, 
 -- which will help identify cities with the most diverse product demand.
select ds.city ,count(distinct fe.product_code) as total_unique_product_sold,
concat(round(sum(`quantity_sold(after_promo)` * base_price)/1000000,2),'M') as total_sales
from dim_stores as ds
join fact_events as fe
on ds.store_id = fe.store_id
join dim_products as dp
on fe.product_code = dp.product_code
group by ds.city
order by total_unique_product_sold desc
limit 5;

-- 6. Generate a report on the duration of campaigns and their total sales.
-- This report will include campaign_name, campaign_duration_days, total_sales, and 
-- average_daily_sales, providing insights into the effectiveness of different campaign lengths.
select dc.campaign_name, concat(datediff(dc.end_date, dc.start_date),' Days') as campaign_duration, 
concat(round(sum(`quantity_sold(after_promo)` * base_price)/1000000,2),'M') as total_sales,
concat(round(round(sum(`quantity_sold(after_promo)` * base_price) /
datediff(dc.end_date, dc.start_date),2)/1000000,2),'M') as avg_daily_sales
from dim_campaigns as dc
join fact_events as fe
on dc.campaign_id = fe.campaign_id
group by dc.campaign_name, dc.start_date, dc.end_date
order by total_sales desc;


-- 7.
select dc.campaign_name, concat(round(sum(base_price * 
`quantity_sold(before_promo)`)/1000000,2),' M') as `total_revenue(before_promo)`,
concat(round(sum(base_price * `quantity_sold(after_promo)`)
/1000000,2),' M') as `total_revenue(after_promo)`
from dim_campaigns dc
join fact_events fe
on dc.campaign_id = fe.campaign_id
group by dc.campaign_name;
-- order by dc.campaign_name

-- 8.
select category,
((sum(`quantity_sold(after_promo)`) - sum(`quantity_sold(before_promo)`)) /
sum(`quantity_sold(before_promo)`)) * 100 as ISU_percentage,
rank() over (order by((sum(`quantity_sold(after_promo)`) - sum(`quantity_sold(before_promo)`)) /
sum(`quantity_sold(before_promo)`)) desc) as rank_order
from dim_products as dp
join fact_events as fe on dp.product_code = fe.product_code
where  campaign_id = 'CAMP_DIW_01'
group by category
order by ISU_percentage desc;

-- 9 Revised Query;
with promo_calulation as
(select dp.product_name, dp.category,
sum(case
when fe.promo_type = "BOGOF" then (fe.base_price-(fe.base_price*0.5))* `quantity_sold(after_promo)`
when fe.promo_type = "33% OFF" then (fe.base_price-(fe.base_price*0.33))* `quantity_sold(after_promo)`
when fe.promo_type = "25% OFF" then (fe.base_price-(fe.base_price*0.25)) * `quantity_sold(after_promo)`
when fe.promo_type = "500 Cashback" then (fe.base_price-500) * `quantity_sold(after_promo)`
when fe.promo_type = " 50% OFF" then (fe.base_price-(fe.base_price*0.5)) * `quantity_sold(after_promo)`
else 0 end ) as total_revenue_after_promo,
sum(fe.base_price* `quantity_sold(before_promo)`) as total_revenue_before_promo
from dim_products dp
left join fact_events fe
on dp.product_code = fe.product_code
group by dp.product_name,dp.category),
product_rank as (select product_name, category,
round(100*(total_revenue_after_promo-total_revenue_before_promo)/ total_revenue_before_promo,2)
as IR_precentage,
rank() over(partition by category order by round(100*(total_revenue_after_promo-total_revenue_before_promo)/ total_revenue_before_promo,2) desc)
as "Ir_rank"
from promo_calulation
order by IR_precentage desc,
category asc
)
select product_name,category,IR_precentage
from product_rank
where Ir_rank<2
order by category ;

show tables