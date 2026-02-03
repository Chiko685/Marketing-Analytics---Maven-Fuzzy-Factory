


--answer question no 2
--we use count for website_session_id to know how many session in total 
--we use distinct just to make sure we dont count for any duplicates because website_session_id is normally the unique number same as customer_id
--we use ::float to change count(distinct order_id) from int to float and to avoid error
--to count conversion rate we use = order_id(count) / website_session_id(count) * 100


select 
count(distinct website_session_id) as sessions,
count(distinct order_id) as orders,
count(distinct order_id)::float / count(distinct website_session_id) * 100 as session_to_order
from website_sessions ws
left join orders o
	using(website_session_id)
where ws.created_at < '2012-04-14'
	and utm_source = 'gsearch'
	and utm_campaign = 'nonbrand';

--Answer question no 3
-- we want to track weekly session till 11 may 2012
-- first we need to extract week using "EXTRACT" and seek for how many session each week
select 
extract('week' from created_at) as week,
count(distinct website_session_id) as sessions
from website_sessions ws
where ws.created_at < '2012-05-11'
	and utm_source = 'gsearch'
	and utm_campaign = 'nonbrand'
group by extract('week' from created_at);


--Answer question no 4
--select (just example to group by type of devices)
--distinct device_type 
--from website_sessions
--group by device_type; 

select 
	device_type, 
	count(distinct website_session_id) as sessions,
	count(distinct order_id) as orders,
	count(distinct order_id)::float / count(distinct website_session_id) * 100 as session_to_order
from website_sessions ws
left join orders o
	using(website_session_id)
where ws.created_at < '2012-05-12'
	AND ws.utm_source = 'gsearch'
	AND ws.utm_campaign = 'nonbrand'
group by device_type
order by sessions DESC;

--Answer question 5
--most view website page

select 
count(distinct website_session_id) as sessions,
pageview_url as pageview_url
from website_pageviews wp
where wp.created_at < '2012-06-10'
group by pageview_url
order by sessions DESC;


--Answer question no 6
select 
count(distinct website_session_id) as session_hitting_page,
pageview_url as first_entry_page
from website_pageviews wp
where created_at < '2012-06-13'
group by first_entry_page
order by session_hitting_page DESC
limit 1;


--Answer question no 7
--bounce rate = (bounce session/total of visitors) * 100
--step 1 identify first website_pageview for relevant session
--make CTE

with first_page_view_by_session as (
	select
		website_session_id,
		min(website_pageview_id) as first_page_id
	from website_pageviews wp
	where created_at < '2012-05-14'
	group by 1
	order by 1
),
session_website_landing_page as(
	select 
		fp.website_session_id,
		wp.pageview_url as landing_page
	from first_page_view_by_session fp
		join website_pageviews wp
			on fp.first_page_id = wp.website_pageview_id
	where wp.pageview_url = '/home'
),
bounce_website_sessions as(
	select 
		sw.website_session_id,
		sw.landing_page,
		count(wp.website_pageview_id) as count_page_viewed
	from session_website_landing_page sw
		essioleft join website_pageviews wp
			using(website_session_id)
	group by 1,2
	having count(wp.website_pageview_id) = 1
)
select
	count(distinct session_website_landing_page.website_session_id) as sessions,
	count(distinct bounce_website_sessions.website_session_id) as bounced_sessions,
	count(distinct bounce_website_sessions.website_session_id)::float/
	count(distinct session_website_landing_page.website_session_id) * 100 as bounce_rate
FROM session_website_landing_page 
	left join bounce_website_sns
	on session_website_landing_page.website_session_id=bounce_website_sessions.website_session_id;	



---- Ma Fuzzy TASK 2
--soal 1:
--Company already on going for 1 month since 12 March 2012
--They want to know session source in which making highest traffic
--Breakdown by UTM source, campagin, http refere, number of session 

select 
	utm_source,
	utm_campaign,
	http_referer,
	count(website_session_id) as session 
from website_sessions 
group by 1, 2,3 
order by 4 desc;   
   



----MAVEN FUZZY PART 2
--ANSWER QUESTION NO 1

--Melihat trend bulanan dari penjualan, revenue, dan profit
select 
extract(year from created_at::date) as year,
extract(month from created_at::date) as month,
count(distinct order_id) as number_of_sales,
sum(price_usd) as total_revenue,
sum(price_usd-cogs_usd) as total_margin
from orders
where created_at < '2013-01-05'
group by 1, 2
--order by 1, 2;

--6 januari launching produk, mau lihat trend bulanan sejak 1 april 2012
--ANSWER QUERY NO 2	
select                                                                                                                                                                                      
	extract(year from ws.created_at::date) as year,
	extract(month from ws.created_at::date) as month,
	count(distinct o.order_id) as orders,
	count(distinct ws.website_session_id) as sessions,                                                   
	count(distinct o.order_id) as orders,                                                               
	count(distinct o.order_id)::float / count(distinct ws.website_session_id) * 100 as conv_rate,
	sum(case when o.primary_product_id = 1 then 1 else 0 end) as product_one_orders, 
	sum(case when o.primary_product_id = 2 then 1 else 0 end) as product_two_orders
	---mengapa keduanya then = 1, karena sebagai penanda kalau nilai itu ada, jika tidak ada maka akan 0
	--setelah itu akan dijumlahkan dengan fungsi SUM
from website_sessions ws                                                                              
left join orders o                                                                                    
	using(website_session_id)  
where ws.created_at > '2012-04-01'                                                                    
	and ws.created_at < '2013-04-06'                                                                  
group by 1,2                                                                                 

--ANSWER QUERY NO 3
--IDENTIFYING NUMBER OF EACH CROSS-SELL
select o.primary_product_id,
count(distinct o.order_id) as orders,
sum(case when oi.product_id = 1 then 1 else 0 end) as x_sell_prod1,
sum(case when oi.product_id = 2 then 1 else 0 end) as x_sell_prod2,
sum(case when oi.product_id = 3 then 1 else 0 end) as x_sell_prod3
--primary_product_id = 1 then 1 menjelaskan kalo 1=ada nilai sedangkan 0=tidak ada nilai
from orders o
left join order_items oi
	on oi.order_id = o.order_id 
and oi.is_primary_item = 0
--bisa filter saat di join 
--ini untuk menghitung cross selling, jd is_primary_item = 0 digunakan untuk menghitung apakah produk tersebut berhasil cross selling di produk lainnya 
where o.created_at >= '2013-09-25'
	and o.created_at <='2013-12-31'
group by 1;


--ANSWER NO 4
--CASE IDENTIFYING REPEAT VISITORS 
with first_session as (
select 
user_id, 
website_session_id
from website_sessions 
where created_at < '2014-11-01'
	and created_at >= '2014-01-01'
	and is_repeat_session = 0
	--kunjungan pertama tiap user_id
),
new_session as (
select 
fs.user_id, 
fs.website_session_id as first_session_id,
ws.website_session_id as repeat_session_id
from first_session fs
left join website_sessions ws
	on ws.user_id = fs.user_id
	and ws.is_repeat_session = 1
	and ws.website_session_id > fs.website_session_id
	and ws.created_at < '2014-06-01'
	and ws.created_at >= '2014-01-01'
),
user_level as (
select user_id,
count(distinct ns.first_session_id) as new_level,
count(distinct ns.repeat_session_id) as repeat_level  
from new_session ns
group by 1
)
select 
repeat_level,
count(distinct user_id) as number_of_user 
from user_level 
group by 1










	
	
















   
   

   
      





                                  







                                                                                            	                                     	
       	                                   
          	
          
          
          
        
          
	         
                                                                          
                                                                          







 
                                       
                                        
                                       